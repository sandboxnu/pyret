import file("ast-util.arr") as AU

# TODO: rather than run upto the point we need here, we should just run the compiler
# with the `lsp` compile-option--and then grab from cache-manager.
fun jump-to-def(locator :: Locator, provide-map :: SD.StringDict<URI>, modules, options, line :: Number, col :: Number) -> E.Either<List<CS.CompileError>, {URI; S.Srcloc}> block:
  doc: ```
    Invariant: provide-map maps dependency keys to URIs
    which ALL must be keys in modules.
  ```
  G.reset()
  A.global-names.reset()
  env = CS.compile-env(locator.get-globals(), modules, provide-map)
  shadow options = locator.get-options(options)
  libs = locator.get-extra-imports()
  mod = locator.get-module()
  ast = cases(PyretCode) mod:
    | pyret-string(module-string) =>
      P.surface-parse(module-string, locator.uri())
    | pyret-ast(module-ast) =>
      module-ast
  end
  var ret = start(time-now())
  fun add-phase(name, value) block:
    if options.collect-all:
      ret := phase(name, value, time-now(), ret)
    else if options.collect-times:
      ret := phase(name, nothing, time-now(), ret)
    else:
      nothing
    end
    value
  end
  # check to make sure that the line and column actually correspond to a name
  # which we must do before any desugaring (which adds in new names)
  options.log-error("[jump-to-def] querying line=" + tostring(line) + " col=" + tostring(col) + " uri=" + locator.uri() + "\n")
  cases(Option) AU.find-name-at(ast, line, col) block:
    | some(name) =>
      options.log-error("[jump-to-def] found name: " + torepr(name) + " at " + name.l.format(true) + "\n")
      ast-ended = AU.append-nothing-if-necessary(ast)
      add-phase("Added nothing", ast-ended)
      wf = W.check-well-formed(ast-ended)
      add-phase("Checked well-formedness", wf)
      checker = if not(options.checks == "none") and not(is-builtin-module(locator.uri())):
        CH.desugar-check
      else:
        CH.desugar-no-checks
      end
      cases(CS.CompileResult) wf block:
        | ok(_) =>
          wf-ast = AU.wrap-toplevels(wf.code)
          checked = checker(wf-ast)
          add-phase(if not(options.checks == "none"): "Desugared (with checks)" else: "Desugared (skipping checks)" end, checked)
          imported = AU.wrap-extra-imports(checked, libs)
          add-phase("Added imports", imported)
          scoped = RS.desugar-scope(imported, env)
          add-phase("Desugared scope", scoped)
          named-result = RS.resolve-names(scoped.ast, locator.uri(), env)
          var any-errors = scoped.errors + named-result.errors
          if is-link(any-errors) block:
            options.log-error("[jump-to-def] scope/resolution errors: " + torepr(any-errors) + "\n")
            left(any-errors)
          else:
            add-phase("Resolved names", named-result)
            spied =
              if options.enable-spies: named-result.ast
              else: named-result.ast.visit(A.default-map-visitor.{
                    method s-block(self, l, stmts):
                      A.s-block(l, stmts.foldr(lam(stmt, acc):
                            if A.is-s-spy-block(stmt): acc
                            else: link(stmt.visit(self), acc)
                            end
                          end, empty))
                    end
                  })
              end
            provides = dummy-provides(locator.uri())
            # Once name resolution has happened, any newly-created s-binds must be added to bindings...
            desugared = D.desugar(spied)
            named-result.env.bindings.merge-now(desugared.new-binds)
            # ...in order to be checked for bad assignments here
            any-errors := RS.check-unbound-ids-bad-assignments(desugared.ast, named-result, env)
            add-phase("Fully desugared", desugared.ast)
            if is-link(any-errors) block:
              options.log-error("[jump-to-def] unbound/bad-assignment errors: " + torepr(any-errors) + "\n")
              left(any-errors)
            else: 
              cases(Option) AU.find-name-key-by-srcloc(named-result.ast, name.l) block:
              | some(key) =>
                options.log-error("[jump-to-def] found key: " + key + "\n")
                cases(Option) named-result.env.bindings.get-now(key) block:
                | some(vb) =>
                  right({vb.origin.uri-of-definition; vb.origin.definition-bind-site})
                | none =>
                  options.log-error("[jump-to-def] no binding for key: " + key + "\n")
                  left([list:])
                end
              | none =>
                options.log-error("[jump-to-def] find-name-key-by-srcloc returned none for srcloc: " + name.l.format(true) + "\n")
                left([list:])
              end
            end
          end
        | err(errors) =>
          options.log-error("[jump-to-def] well-formedness errors: " + torepr(errors) + "\n")
          left(errors)
      end
    | none =>
      options.log-error("[jump-to-def] find-name-at returned none for line=" + tostring(line) + " col=" + tostring(col) + "\n")
      left([list:])
  end
end
