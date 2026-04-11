const WebSocket = require('./lsp/node_modules/ws');
const path = require('path');

const socketPath = process.argv[2];
const program = path.resolve(process.argv[3] || 'test-lsp.arr');
const url = socketPath.startsWith('/') ? `ws+unix://${socketPath}` : `ws://localhost:${socketPath}`;

function sendCheck(label, filePath) {
  return new Promise((resolve, reject) => {
    const client = new WebSocket(url);
    client.on('open', () => {
      const msg = JSON.stringify({
        command: 'query',
        query: 'check',
        compileOptions: JSON.stringify({ program: filePath }),
        queryOptions: JSON.stringify({}),
      });
      console.log(`[${label}] Sending check for ${filePath}`);
      var start = Date.now();
      client.send(msg);
      client.on('message', (data) => {
        const msg = JSON.parse(data.toString());
        if (msg.type === 'check-success') {
          console.log(`[${label}] check-success in ${Date.now() - start}ms, ${msg.diagnostics.length} diagnostic(s)`);
          msg.diagnostics.forEach(d => {
            if (d['start-line'] !== undefined)
              console.log(`  [${label}]   ${d['start-line']}:${d['start-column']}-${d['end-line']}:${d['end-column']} ${d.message.slice(0, 80)}`);
            else
              console.log(`  [${label}]   (no loc) ${d.message.slice(0, 80)}`);
          });
          client.close();
          resolve(msg.diagnostics);
        } else if (msg.type === 'echo-err') {
          console.log(`[${label}] err: ${msg.contents}`);
        }
      });
    });
    client.on('close', () => resolve([]));
    client.on('error', (err) => reject(err));
  });
}

(async () => {
  console.log(`Connecting to ${url}\n`);
  const badFile = path.resolve(process.argv[3] || 'test-lsp.arr');
  const goodFile = path.resolve(process.argv[4] || 'test-lsp2.arr');
  await sendCheck('bad-file', badFile);
  console.log('');
  await sendCheck('good-file', goodFile);
  process.exit(0);
})();
