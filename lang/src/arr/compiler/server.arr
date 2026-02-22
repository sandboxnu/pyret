provide *

import either as E
import json as J
import pathlib as P
import string-dict as SD
import render-error-display as RED
import js-file("server") as S
import file("./cli-module-loader.arr") as CLI
import file("./compile-structs.arr") as CS
import file("./compile-lib.arr") as CL
import file("locators/builtin.arr") as B

fun compile(options):
  outfile = cases(Option) options.get("outfile"):
    | some(v) => v
    | none => options.get-value("program") + ".jarr"
  end
  compile-opts = CS.make-default-compile-options(options.get-value("this-pyret-dir"))
  CLI.build-runnable-standalone(
    options.get-value("program"),
    options.get-value("require-config"),
    outfile,
    compile-opts.{
      base-dir: options.get-value("base-dir"),
      this-pyret-dir : options.get-value("this-pyret-dir"),
      check-mode : not(options.get("no-check-mode").or-else(false)),
      type-check : options.get("type-check").or-else(false),
      allow-shadowed : options.get("allow-shadowed").or-else(false),
      collect-all: options.get("collect-all").or-else(false),
      ignore-unbound: options.get("ignore-unbound").or-else(false),
      proper-tail-calls: options.get("improper-tail-calls").or-else(true),
      compiled-cache: options.get("compiled-dir").or-else("./compiled"),
      compiled-read-only: options.get("compiled-read-only").or-else(empty),
      standalone-file: options.get("standalone-file").or-else(compile-opts.standalone-file),
      checks: options.get-value("checks"),
      checks-format: options.get-value("checks-format"),
      display-progress: options.get("display-progress").or-else(true),
      log: options.get("log").or-else(compile-opts.log),
      log-error: options.get("log-error").or-else(compile-opts.log-error),
      deps-file: options.get("deps-file").or-else(compile-opts.deps-file),
      user-annotations: options.get("user-annotations").or-else(compile-opts.user-annotations)
    })
end

# TODO: hook upto jumpto def......

fun serve(port, pyret-dir):
  S.make-server(port, lam(cmd, msg, send-message) block:
    # print("Got message in pyret-land: " + msg)
    opts = J.read-json(msg).native()
    # print(torepr(opts))
    # print("\n")
    when opts.has-key("builtin-js-dir"):
      if is-List(opts.get-value("builtin-js-dir")):
        B.set-builtin-js-dirs(opts.get-value("builtin-js-dir"))
      else:
        B.set-builtin-js-dirs([list: opts.get-value("builtin-js-dir")])
      end
    end
    when opts.has-key("builtin-arr-dir"):
      if is-List(opts.get-value("builtin-arr-dir")):
        B.set-builtin-arr-dirs(opts.get-value("builtin-arr-dir"))
      else:
        B.set-builtin-arr-dirs([list: opts.get-value("builtin-arr-dir")])
      end
    end
    when opts.has-key("allow-builtin-overrides"):
      B.set-allow-builtin-overrides(opts.get-value("allow-builtin-overrides"))
    end
    fun log(s, to-clear):
      d = [SD.string-dict: "type", J.j-str("echo-log"), "contents", J.j-str(s)]
      with-clear = cases(Option) to-clear:
        | none => d.set("clear-first", J.j-bool(false))
        | some(n) => d.set("clear-first", J.j-num(n))
      end
      send-message(J.j-obj(with-clear).serialize())
    end
    fun err(s):
      d = [SD.string-dict: "type", J.j-str("echo-err"), "contents", J.j-str(s)]
      send-message(J.j-obj(d).serialize())
    end
    with-logger = opts.set("log", log)
    with-error = with-logger.set("log-error", err)
    with-pyret-dir = with-error.set("this-pyret-dir", pyret-dir)
    with-compiled-read-only-dirs = with-pyret-dir.set("compiled-read-only",
          link(P.resolve(P.join(pyret-dir, "lib-compiled")), empty))
    with-perilous = if opts.has-key("perilous") and opts.get-value("perilous"):
        with-compiled-read-only-dirs.set("user-annotations", false)
      else:
        with-compiled-read-only-dirs
      end
    with-require-config = with-perilous.set("require-config",
      opts.get("require-config").or-else(P.resolve(P.join(pyret-dir, "config.json"))))
    ask:
    | cmd == "compile" then:
      result = run-task(lam():
        compile(with-require-config)
      end)
      cases(E.Either) result block:
        | right(exn) =>
          err-str = RED.display-to-string(exn-unwrap(exn).render-reason(), tostring, empty)
          err(err-str + "\n")
          d = [SD.string-dict: "type", J.j-str("compile-failure")]
          send-message(J.j-obj(d).serialize())
        | left(val) =>
          d = [SD.string-dict: "type", J.j-str("compile-success")]
          send-message(J.j-obj(d).serialize())
          nothing
      end
    | cmd == "info" then:
      result = run-task(lam() block:
        options = with-require-config
        program = options.get-value("program")
        line = options.get-value("line")
        col = options.get-value("col")
        shadow pyret-dir = options.get-value("this-pyret-dir")
        compile-opts = CS.make-default-compile-options(pyret-dir).{
          base-dir: options.get("base-dir").or-else(P.resolve(".")),
          this-pyret-dir: pyret-dir,
          compiled-cache: options.get("compiled-dir").or-else("./compiled"),
          compiled-read-only: options.get-value("compiled-read-only"),
          display-progress: false,
          log: lam(s, _): nothing end,
          log-error: err,
        }
        base-module = CS.dependency("file", [list: program])
        base = CLI.module-finder({
          current-load-path: P.resolve(compile-opts.base-dir),
          cache-base-dir: compile-opts.compiled-cache,
          compiled-read-only-dirs: compile-opts.compiled-read-only.map(P.resolve),
          url-file-mode: compile-opts.url-file-mode
        }, base-module)
        wl = CL.compile-worklist(CLI.module-finder, base.locator, base.context)
        max-dep-times = CL.dep-times-from-worklist(wl)
        shadow wl = for map(located from wl):
          located.{ locator: CLI.get-cached-if-available-known-mtimes(compile-opts.compiled-cache, located.locator, max-dep-times) }
        end
        starter-modules = CL.modules-from-worklist(wl,
          CLI.get-loadable(compile-opts.compiled-cache, compile-opts.compiled-read-only.map(P.resolve), _, _))
        compiled = CL.compile-program-with(wl, starter-modules, compile-opts)
        # find the worklist entry for the requested file
        base-wl-entry = for find(entry from wl):
          entry.locator.uri() == base.locator.uri()
        end.value
        provide-map = for fold(acc from SD.make-string-dict(), k from base-wl-entry.dependency-map.keys-now().to-list()):
          acc.set(k, base-wl-entry.dependency-map.get-value-now(k).uri())
        end
        CL.jump-to-def(base.locator, provide-map, compiled.modules, compile-opts, line, col)
      end)
      cases(E.Either) result block:
        | right(exn) =>
          err-str = RED.display-to-string(exn-unwrap(exn).render-reason(), tostring, empty)
          err(err-str + "\n")
          d = [SD.string-dict: "type", J.j-str("jump-to-def-failure")]
          send-message(J.j-obj(d).serialize())
        | left(jump-result) =>
          cases(E.Either) jump-result block:
            | left(errors) =>
              err("jump-to-def: no result (errors: " + torepr(errors) + ")\n")
              d = [SD.string-dict: "type", J.j-str("jump-to-def-failure")]
              send-message(J.j-obj(d).serialize())
            | right(loc-info) =>
              srcloc = loc-info.{1}
              d = [SD.string-dict:
                "type", J.j-str("jump-to-def-success"),
                "uri", J.j-str(loc-info.{0}),
                "start-line", J.j-num(srcloc.start-line),
                "start-column", J.j-num(srcloc.start-column),
                "end-line", J.j-num(srcloc.end-line),
                "end-column", J.j-num(srcloc.end-column)
              ]
              send-message(J.j-obj(d).serialize())
          end
      end
    end
  end)
end
