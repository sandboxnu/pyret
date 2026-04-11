provide *

# NOTE: New LSP/queries go here as functions that take the cache-manager and
# query parameters, then return results. The cache-manager has surface-ast,
# named-result, and loadable for every compiled module.

import either as E
import srcloc as S
import error-display as ED
import ast as A
import render-error-display as RED
import file("ast-util.arr") as AU
import file("compile-structs.arr") as CS

# TODO: debug / figure out where exactly we have to check locations
fun find-name-key-by-srcloc(resolved :: A.Program, srcloc :: A.Loc) -> Option<String> block:
  var result-mangled-name = none
  visitor = A.default-iter-visitor.{
    # Use sites: s-id(use-l, atom/global) — match on the outer l, return inner key
    method s-id(self, l, id):
      if l == srcloc block:
        result-mangled-name := some(id.key())
        false
      else:
        true
      end
    end,
    method s-id-var(self, l, id):
      if l == srcloc block:
        result-mangled-name := some(id.key())
        false
      else:
        true
      end
    end,
    method s-id-letrec(self, l, id, safe):
      if l == srcloc block:
        result-mangled-name := some(id.key())
        false
      else:
        true
      end
    end,
    # Binding sites: s-atom/s-global appear directly with bind-l — only match
    # if the user clicked exactly on a binding site (rare but possible)
    method s-atom(self, l, base, serial):
      if l == srcloc block:
        result-mangled-name := some(A.s-atom(l, base, serial).key())
        false
      else:
        true
      end
    end,
    method s-global(self, l, s):
      if l == srcloc block:
        result-mangled-name := some(A.s-global(l, s).key())
        false
      else:
        true
      end
    end
  }

  resolved.visit(visitor)
  result-mangled-name
end

is-s-name = A.is-s-name
fun find-name-at(prog :: A.Program, line :: Number, col :: Number) -> Option<A.Name%(is-s-name)> block:
  var result-name = none
  visitor = A.default-iter-visitor.{
    method s-name(self, l, s):
      cases (A.Loc) l:
        | builtin(_) => true
        | srcloc(_, sl, sc, _, el, ec, _) =>
          if (sl <= line) and (line <= el) and (sc <= col) and (col <= ec) block:
            result-name := some(A.s-name(l, s))
            false
          else:
            true
          end
      end
    end
  }

  prog.visit(visitor)
  result-name
end

fun jump-to-def(cache-manager, uri :: String, line :: Number, col :: Number) -> E.Either<String, {String; S.Srcloc}>:
  cases(Option) cache-manager.get-surface-ast(uri):
    | none => E.left("AST not available")
    | some(ast) =>
      cases(Option) find-name-at(ast, line, col):
        | none => E.left("Did not select an identifier")
        | some(name) =>
          cases(Option) cache-manager.get-named-result(uri):
            | none => E.left("Resolved AST not available")
            | some(named-result) =>
              cases(Option) find-name-key-by-srcloc(named-result.ast, name.l):
                | none => E.left("Post-resolution name not found")
                | some(key) =>
                  cases(Option) named-result.env.bindings.get-now(key):
                    | none => E.left("No identifier binding found")
                    | some(vb) =>
                      loc = vb.origin.definition-bind-site
                      if S.is-srcloc(loc):
                        E.right({vb.origin.uri-of-definition; loc})
                      else:
                        E.left("Definition is a builtin with no source location")
                      end
                  end
              end
          end
      end
  end
end

fun first-srcloc(ed :: ED.ErrorDisplay) -> Option<S.Srcloc>:
  doc: "Walk an ErrorDisplay tree and return the first concrete srcloc found."
  fun srcloc-opt(l):
    if S.is-srcloc(l): some(l) else: none end
  end
  fun first-in-list(eds):
    cases(List) eds:
      | empty => none
      | link(first, rest) =>
        cases(Option) first-srcloc(first):
          | some(l) => some(l)
          | none => first-in-list(rest)
        end
    end
  end
  cases(ED.ErrorDisplay) ed:
    | loc(l)                    => srcloc-opt(l)
    | cmcode(l)                 => srcloc-opt(l)
    | highlight(contents, locs, _) =>
      concrete = locs.filter(S.is-srcloc)
      if is-link(concrete): some(concrete.first)
      else: first-srcloc(contents)
      end
    | loc-display(l, _, contents) =>
      if S.is-srcloc(l): some(l) else: first-srcloc(contents) end
    | paragraph(contents)       => first-in-list(contents)
    | v-sequence(contents)      => first-in-list(contents)
    | bulleted-sequence(contents) => first-in-list(contents)
    | h-sequence(contents, _)   => first-in-list(contents)
    | h-sequence-sep(contents, _, _) => first-in-list(contents)
    | code(contents)            => first-srcloc(contents)
    | optional(contents)        => first-srcloc(contents)
    | text(_)                   => none
    | embed(_)                  => none
    | maybe-stack-loc(_, _, _, _) => none
  end
end

fun compile-error-loc(err :: CS.CompileError) -> Option<S.Srcloc>:
  doc: "Extract the primary source location directly from a CompileError variant's fields."
  fun srcloc-opt(l):
    if S.is-srcloc(l): some(l) else: none end
  end
  fun first-srcloc-in-list(locs):
    cases(List) locs.filter(S.is-srcloc):
      | empty => none
      | link(first, _) => some(first)
    end
  end
  cases(CS.CompileError) err:
    | wf-err(_, loc)                                      => srcloc-opt(loc)
    | wf-empty-block(loc)                                 => srcloc-opt(loc)
    | wf-err-split(_, locs)                               => first-srcloc-in-list(locs)
    | reserved-name(loc, _)                               => srcloc-opt(loc)
    | contract-on-import(loc, _, _, _)                    => srcloc-opt(loc)
    | contract-redefined(loc, _, _)                       => srcloc-opt(loc)
    | contract-non-function(loc, _, _, _)                 => srcloc-opt(loc)
    | contract-inconsistent-names(loc, _, _)              => srcloc-opt(loc)
    | contract-inconsistent-params(loc, _, _)             => srcloc-opt(loc)
    | contract-unused(loc, _)                             => srcloc-opt(loc)
    | contract-bad-loc(loc, _, _)                         => srcloc-opt(loc)
    | zero-fraction(loc, _)                               => srcloc-opt(loc)
    | mixed-binops(exp-loc, _, _, _, _)                   => srcloc-opt(exp-loc)
    | block-ending(l, _, _)                               => srcloc-opt(l)
    | single-branch-if(expr)                              => srcloc-opt(expr.l)
    | unwelcome-where(_, loc, _)                          => srcloc-opt(loc)
    | non-example(expr)                                   => srcloc-opt(expr.l)
    | tuple-get-bad-index(l, _, _, _)                     => srcloc-opt(l)
    | import-arity-mismatch(l, _, _, _, _)                => srcloc-opt(l)
    | no-arguments(expr)                                  => srcloc-opt(expr.l)
    | non-toplevel(_, l, _)                               => srcloc-opt(l)
    | unwelcome-test(loc)                                 => srcloc-opt(loc)
    | unwelcome-test-refinement(_, op)                    => srcloc-opt(op.l)
    | underscore-as(l, _)                                 => srcloc-opt(l)
    | underscore-as-pattern(l)                            => srcloc-opt(l)
    | underscore-as-expr(l)                               => srcloc-opt(l)
    | underscore-as-ann(l)                                => srcloc-opt(l)
    | block-needed(expr-loc, _)                           => srcloc-opt(expr-loc)
    | name-not-provided(name-loc, _, _, _)                => srcloc-opt(name-loc)
    | unbound-id(id)                                      => srcloc-opt(id.l)
    | unbound-var(_, loc)                                 => srcloc-opt(loc)
    | unbound-type-id(ann)                                => srcloc-opt(ann.l)
    | type-id-used-in-dot-lookup(loc, _)                  => srcloc-opt(loc)
    | type-id-used-as-value(id, _)                        => srcloc-opt(id.l)
    | unexpected-type-var(loc, _)                         => srcloc-opt(loc)
    | pointless-var(loc)                                  => srcloc-opt(loc)
    | pointless-rec(loc)                                  => srcloc-opt(loc)
    | pointless-shadow(loc)                               => srcloc-opt(loc)
    | bad-assignment(iuse, _)                             => srcloc-opt(iuse.l)
    | mixed-id-var(_, var-loc, _)                         => srcloc-opt(var-loc)
    | shadow-id(_, new-loc, _, _)                         => srcloc-opt(new-loc)
    | duplicate-id(_, new-loc, _)                         => srcloc-opt(new-loc)
    | duplicate-field(_, new-loc, _)                      => srcloc-opt(new-loc)
    | same-line(a, _, _)                                  => srcloc-opt(a)
    | template-same-line(a, _)                            => srcloc-opt(a)
    | type-mismatch(type-1, type-2)                       =>
        if type-1.l.before(type-2.l): srcloc-opt(type-1.l) else: srcloc-opt(type-2.l) end
    | incorrect-type(_, bad-loc, _, _)                    => srcloc-opt(bad-loc)
    | incorrect-type-expression(_, bad-loc, _, _, _)      => srcloc-opt(bad-loc)
    | bad-type-instantiation(app-type, _)                 => srcloc-opt(app-type.l)
    | incorrect-number-of-args(app-expr, _)               => srcloc-opt(app-expr.l)
    | method-missing-self(expr)                           => srcloc-opt(expr.l)
    | apply-non-function(app-expr, _)                     => srcloc-opt(app-expr.l)
    | tuple-too-small(_, _, _, _, access-loc)             => srcloc-opt(access-loc)
    | object-missing-field(_, _, _, access-loc)           => srcloc-opt(access-loc)
    | duplicate-variant(_, found, _)                      => srcloc-opt(found)
    | data-variant-duplicate-name(_, found, _)            => srcloc-opt(found)
    | duplicate-is-variant(_, _, base-found)              => srcloc-opt(base-found)
    | duplicate-is-data(_, _, base-found)                 => srcloc-opt(base-found)
    | duplicate-is-data-variant(_, _, base-found)         => srcloc-opt(base-found)
    | duplicate-branch(_, found, _)                       => srcloc-opt(found)
    | unnecessary-branch(branch, _, _)                    => srcloc-opt(branch.pat-loc)
    | unnecessary-else-branch(_, loc)                     => srcloc-opt(loc)
    | non-exhaustive-pattern(_, _, loc)                   => srcloc-opt(loc)
    | cant-match-on(_, _, loc)                            => srcloc-opt(loc)
    | different-branch-types(l, _)                        => srcloc-opt(l)
    | incorrect-number-of-bindings(branch, _)             => srcloc-opt(branch.pat-loc)
    | cases-singleton-mismatch(_, branch-loc, _)          => srcloc-opt(branch-loc)
    | given-parameters(_, loc)                            => srcloc-opt(loc)
    | unable-to-instantiate(loc)                          => srcloc-opt(loc)
    | unable-to-infer(loc)                                => srcloc-opt(loc)
    | unann-failed-test-inference(function-loc)           => srcloc-opt(function-loc)
    | toplevel-unann(arg)                                 => srcloc-opt(arg.l)
    | polymorphic-return-type-unann(function-loc)         => srcloc-opt(function-loc)
    | binop-type-error(binop, _, _, _, _)                 => srcloc-opt(binop.l)
    | cant-typecheck(_, loc)                              => srcloc-opt(loc)
    | unsupported(_, blame-loc)                           => srcloc-opt(blame-loc)
    | non-object-provide(loc)                             => srcloc-opt(loc)
    | no-module(loc, _)                                   => srcloc-opt(loc)
    | table-empty-header(loc)                             => srcloc-opt(loc)
    | table-empty-row(loc)                                => srcloc-opt(loc)
    | table-row-wrong-size(_, _, row)                     => srcloc-opt(row.l)
    | table-duplicate-column-name(column1, _)             => srcloc-opt(column1.l)
    | table-reducer-bad-column(ext, _)                    => srcloc-opt(ext.col.l)
    | table-sanitizer-bad-column(san-expr, _)             => srcloc-opt(san-expr.name.l)
    | load-table-bad-number-srcs(lte, _)                  => srcloc-opt(lte.l)
    | load-table-duplicate-sanitizer(_, _, dup)           => srcloc-opt(dup.l)
    | load-table-no-body(lte)                             => srcloc-opt(lte.l)
  end
end

fun get-diagnostics(compiled) -> List<{String; Option<S.Srcloc>}>:
  doc: "Extract compile errors from a CompiledProgram as {message; maybe-loc} pairs."
  error-loadables = compiled.loadables.filter(lam(cr):
    CS.is-module-as-string(cr) and CS.is-err(cr.result-printer)
  end)
  for fold(diagnostics from empty, loadable from error-loadables):
    cases(CS.CompileResult) loadable.result-printer:
      | err(problems) =>
        for fold(acc from diagnostics, problem from problems):
          msg = RED.display-to-string(problem.render-reason(), tostring, empty)
          maybe-loc = compile-error-loc(problem)
          link({msg; maybe-loc}, acc)
        end
      | ok(_) => diagnostics
    end
  end
end
