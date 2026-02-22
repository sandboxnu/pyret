/** @satisfies {PyretModule} */
({
  provides: {
    values: {
      "make-server": "tany"
    }
  },
  requires: [],
  nativeRequires: ['http', 'ws', 'fs'],
  theModule: function(
    runtime,
    _,
    uri,
    /** @type {import('node:http')} */ http,
    ws,
    /** @type {import('node:fs')} */ fs,
  ) {
    /** @import ws from "ws"  */

    const INFO = 4;
    const LOG = 3;
    const WARN = 2;
    const ERROR = 1;
    const SILENT = 0;
    let LOG_LEVEL = ERROR;

    function makeLogger(/** @type {number} */ level) {
      return function(/** @type {...any} */...args) {
        if(LOG_LEVEL >= level) {
          console.log.apply(console, ["[server] ", new Date()].concat(args));
        }
      }
    }

    const info = makeLogger(INFO);
    const log = makeLogger(LOG);
    const warn = makeLogger(WARN);
    const error = makeLogger(ERROR);


    // Port is a string for a file path, like /tmp/some-sock,
    const makeServer = function(/** @type {string} */ port, /** @type {PyretFunction} */ onmessage) {

      /**
       * @typedef {{command: string, options: unknown, respond: function, respondJSON: function, closeConn: function}} QueueItem
       */

      /** @type {QueueItem[]} */
      let runQueue = [];
      let running = false;

      function tryQueue() {
        if (running || runQueue.length === 0) { return; }
        running = true;
        const current = runQueue.shift();
        info(`Running queued command: ${current.command}, queue length now ${runQueue.length}`);
        runtime.runThunk(function() {
          return onmessage.app(current.command, current.options, current.respondForPy);
        }, function(result) {
          if (runtime.isFailureResult(result)) {
            const exn = result.exn;
            const inner = exn && exn.exn !== undefined ? exn.exn : exn;
            error("Failed (raw exn):", inner);
            error("Failed (stack):", exn && exn.stack);
            error("Failed (pyretStack):", exn && exn.pyretStack);
            const exnStr = inner !== undefined
              ? (typeof inner === 'object' ? JSON.stringify(inner) : String(inner))
              : String(exn);
            current.respondJSON({type: "echo-err", contents: "Internal error: " + exnStr});
            if (exn && exn.stack) { current.respondJSON({type: "echo-err", contents: exn.stack}); }
          }
          current.closeConn();
          running = false;
          tryQueue();
        });
      }

      //info("Starting up server");
      return runtime.pauseStack(function(restarter) {
        const server = http.createServer(function(request, response) {
          response.writeHead(404);
          response.end();
        });
        server.listen(port, function() {
          info((new Date()) + ' Server is listening on port ' + port);
          info((new Date()) + ' The server\'s working directory is ' + process.cwd());
        });

        // At this point, using port as a file socket didn't fail, so make sure
        // to remove it when we shut down.
        process.on('SIGINT', function() {
          if(fs.existsSync(port)) {
            fs.unlinkSync(port);
          }
        });
        process.on('exit', function() {
          if(fs.existsSync(port)) {
            fs.unlinkSync(port);
          }
        });

        /** @type {ws.Server} */
        const wsServer = new ws.Server({
          server: server
        });

        wsServer.on('connection', function(connection) {
          function respond(jsonData) {
            info("Sending: ", jsonData);
            connection.send(jsonData);
            return runtime.nothing;
          }
          function respondJSON(json) { return respond(JSON.stringify(json)); }
          const respondForPy = runtime.makeFunction(respond, "respond");
          function closeConn() { connection.close(); }


          info(`${new Date()} Connection accepted.`);


          // TODO: query options, don't run all stages of the compiler, etc
          // TODO: thread through info
          /**
           * @typedef {{command: 'stop'} |
           *           {command: 'shutdown'} |
           *           {command: 'compile', compileOptions: unknown} |
           *           {command: 'info', compileOptions: unknown, queryOptions: unknown}}
           *  ServerMessage
           */

          connection.on('message', function(message) {
            info(`Received Message: ${message}`);

            /** @type {ServerMessage} */
            const parsed = JSON.parse(message);

            switch (parsed.command) {
              case "stop": {
                runtime.schedulePause(function(restarter) {
                  restarter.break();
                });
                tryQueue();
                break;
              }
              case "shutdown": {
                runtime.breakAll();
                info("Exiting due to shutdown request");
                process.exit(0);
                break;
              }
              case "compile":
              case "info": {
                runQueue.push({command: parsed.command, options: parsed.compileOptions, respondForPy, respondJSON, closeConn});
                tryQueue();
                break;
              }
            }
          });
          connection.on('close', function(reasonCode, description) {
            // info((new Date()) + ' Peer ' + connection.remoteAddress + ' disconnected.');
          });
        });

        info("Server startup successful");
        if(process.send) {
          process.send({type: 'success'});
        }

        process.on('SIGINT', function() {
          info("Caught interrupt signal, exiting server");
          restarter.resume(runtime.nothing)
        });
      });
    };

    return runtime.makeModuleReturn({
      "make-server": runtime.makeFunction(makeServer, "make-server")
    }, {});
  }
})
