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
    method a-name(self, l, id):
      if l == srcloc block:
        result-mangled-name := some(id.key())
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

# Note(Jacob): This function was made to be a separate helper for when we need to jump to the definition
# site of a type that was defined by the user. Technically, the functionality implemented within # this function can be pushed into 'find-name-at'; however, this would require changing the return
# type and thus might break some of the usages.
fun find-ann-at(prog :: A.program, line :: Number, col :: Number) -> Option<A.Ann%(A.is-a-name)> block:
  var result-ann = none
  vis = A.defualt-iter-visitor.{
    method a-name(self, l, id):
      cases (Loc) l:
        | builtin(_) => true
        | srcloc(_, sl, sc, _, el, ec, _) =>
          if (sl <= line) and (line <= el) and (sc <= col) and (col <= ec) block:
            result-ann := some(A.a-name(l, id))
            false
          else:
            true
          end
      end
    end
  }
  prog.visit(vis)
  result-ann
end


fun jump-to-def(cache-manager, uri :: String, line :: Number, col :: Number) -> E.Either<String, {String; S.Srcloc}>:
  cases(Option) cache-manager.get-surface-ast(uri):
    | none => E.left("AST not available")
    | some(ast) =>
      cases(Option) cache-manager.get-named-result(uri):
        | none => E.left("Resolved AST not available")
        | some(named-result) =>
          cases(Option) AU.find-name-at(ast, line, col):
            | some(name) =>
              cases(Option) AU.find-name-key-by-srcloc(named-result.ast, name.l):
                | none => E.left("Post-resolution name not found")
                | some(key) =>
                  cases(Option) named-result.env.bindings.get-now(key):
                    | none => E.left("No value identifier binding found")
                    | some(vb) =>
                      E.right({vb.origin.uri-of-definition; vb.origin.definition-bind-site})
                  end
              end
            | none =>
              cases(Option) AU.find-ann-at(ast, line, col):
                | none => E.left("Did not select an identifier")
                | some(ann) =>
                  cases(Option) AU.find-name-key-by-srcloc(named-result.ast, ann.l):
                    | none => E.left("Post-resolution name not found")
                    | some(key) =>
                      cases(Option) named-result.env.type-bindings.get-now(key):
                        | none => E.left("No type identifier binding found")
                        | some(tb) =>
                          E.right({tb.origin.uri-of-definition; tb.origin.definition-bind-site})
                      end
                  end
              end
          end
      end
  end
end

fun first-srcloc(ed :: ED.ErrorDisplay) -> Option<S.Srcloc>:
  doc: "Walk an ErrorDisplay tree and return the first concrete srcloc found."
  cases(ED.ErrorDisplay) ed:
    | loc(l) =>
      if S.is-srcloc(l): some(l) else: none end
    | cmcode(l) =>
      if S.is-srcloc(l): some(l) else: none end
    | highlight(contents, locs, _) =>
      srclocs = locs.filter(S.is-srcloc)
      if is-link(srclocs): some(srclocs.first)
      else: first-srcloc(contents)
      end
    | loc-display(l, _, contents) =>
      if S.is-srcloc(l): some(l)
      else: first-srcloc(contents)
      end
    | paragraph(contents) => first-srcloc-list(contents)
    | v-sequence(contents) => first-srcloc-list(contents)
    | bulleted-sequence(contents) => first-srcloc-list(contents)
    | h-sequence(contents, _) => first-srcloc-list(contents)
    | h-sequence-sep(contents, _, _) => first-srcloc-list(contents)
    | code(contents) => first-srcloc(contents)
    | optional(contents) => first-srcloc(contents)
    | text(_) => none
    | embed(_) => none
    | maybe-stack-loc(_, _, _, _) => none
  end
end

fun first-srcloc-list(eds :: List<ED.ErrorDisplay>) -> Option<S.Srcloc>:
  cases(List) eds:
    | empty => none
    | link(first, rest) =>
      cases(Option) first-srcloc(first):
        | some(l) => some(l)
        | none => first-srcloc-list(rest)
      end
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
          rendered = problem.render-reason()
          msg = RED.display-to-string(rendered, tostring, empty)
          maybe-loc = first-srcloc(rendered)
          link({msg; maybe-loc}, acc)
        end
      | ok(_) => diagnostics
    end
  end
end
