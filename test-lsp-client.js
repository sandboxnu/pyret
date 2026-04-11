const WebSocket = require('./lsp/node_modules/ws');
const path = require('path');

const PORT = process.argv[2] || '1701';
const url = PORT.startsWith('/') ? `ws+unix://${PORT}` : `ws://localhost:${PORT}`;

const program = path.resolve(process.argv[3] || 'test-lsp.arr');
const line = parseInt(process.argv[4] || '2', 10);
const col = parseInt(process.argv[5] || '4', 10);

function sendQuery(label) {
  return new Promise((resolve, reject) => {
    const client = new WebSocket(url);

    client.on('open', () => {
      const msg = JSON.stringify({
        command: 'query',
        query: 'jump-to-def',
        compileOptions: JSON.stringify({
          program,
          'base-dir': '.',
        }),
        queryOptions: JSON.stringify({ line, col }),
      });
      console.log(`[${label}] Sending query for ${program}:${line}:${col}`);
      var start = Date.now();
      client.send(msg);

      client.on('message', (data) => {
        const msg = JSON.parse(data.toString());
        if (msg.type === 'jump-to-def-success' || msg.type === 'jump-to-def-failure') {
          console.log(`[${label}] ${msg.type} in ${Date.now() - start}ms`);
          if (msg.type === 'jump-to-def-success') {
            console.log(`[${label}]   -> ${msg.uri}:${msg['start-line']}:${msg['start-column']}`);
          }
          resolve(msg);
        } else if (msg.type === 'echo-err') {
          console.log(`[${label}] err: ${msg.contents}`);
        } else if (msg.type === 'echo-log') {
          // skip log noise
        }
      });
    });

    client.on('close', () => resolve(null));
    client.on('error', (err) => {
      console.error(`[${label}] error: ${err.message}`);
      reject(err);
    });
  });
}

(async () => {
  console.log(`Connecting to ${url}\n`);
  await sendQuery('cold');
  console.log('');
  await sendQuery('warm');
  process.exit(0);
})();
