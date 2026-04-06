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
