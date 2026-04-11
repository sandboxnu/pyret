provide *

# NOTE: New LSP/queries go here as functions that take the cache-manager and
# query parameters, then return results. The cache-manager has surface-ast,
# named-result, and loadable for every compiled module.

import either as E
import srcloc as S
import file("ast-util.arr") as AU
import file("compile-structs.arr") as CS

fun jump-to-def(cache-manager, uri :: String, line :: Number, col :: Number) -> E.Either<List<CS.CompileError>, {String; S.Srcloc}>:
  cases(Option) cache-manager.get-surface-ast(uri):
    | none => E.left([list:])
    | some(ast) =>
      cases(Option) AU.find-name-at(ast, line, col):
        | none => E.left([list:])
        | some(name) =>
          cases(Option) cache-manager.get-named-result(uri):
            | none => E.left([list:])
            | some(named-result) =>
              cases(Option) AU.find-name-key-by-srcloc(named-result.ast, name.l):
                | none => E.left([list:])
                | some(key) =>
                  cases(Option) named-result.env.bindings.get-now(key):
                    | none => E.left([list:])
                    | some(vb) =>
                      E.right({vb.origin.uri-of-definition; vb.origin.definition-bind-site})
                  end
              end
          end
      end
  end
end

fun document-symbols(cache-manager, uri :: String)
  -> E.Either<List<CS.CompileError>, List<{String; String; S.Srcloc}>>:
  cases(Option) cache-manager.get-named-result(uri):
    | none => E.left([list:])
    | some(named-result) =>
      cases(CS.ComputedEnvironment) named-result.env:
        | computed-none => E.left([list:])
        | computed-env(_, _, _, _, _, _, _) =>
          env = named-result.env

          value-symbols = for fold(acc from [list:], k from env.env.keys-list()):
        vb = env.env.get-value(k)
        loc = vb.origin.definition-bind-site
        if vb.origin.new-definition and S.is-srcloc(loc):
          kind = cases(CS.ValueBinder) vb.binder:
            | vb-letrec => "vb-letrec"
            | vb-let => "vb-let"
            | vb-var => "vb-var"
          end
          link({vb.origin.original-name.toname(); kind; loc}, acc)
        else:
          acc
        end
      end

      type-symbols = for fold(acc from [list:], k from env.type-env.keys-list()):
        tb = env.type-env.get-value(k)
        loc = tb.origin.definition-bind-site
        if tb.origin.new-definition and S.is-srcloc(loc):
          link({tb.origin.original-name.toname(); "type"; loc}, acc)
        else:
          acc
        end
      end

          # NOTE: module-env is skipped because all module bindings come from
          # import statements (both explicit and implicit), not definitions.
          E.right(value-symbols + type-symbols)
      end
  end
end
