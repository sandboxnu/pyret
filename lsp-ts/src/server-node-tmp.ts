import { createConnection, ProposedFeatures } from 'vscode-languageserver/node';

import {
	Connection,
	ServerCapabilities,
	TextDocuments,
	TextDocumentSyncKind,
} from 'vscode-languageserver';
import { TextDocument } from 'vscode-languageserver-textdocument';

const connection = createConnection(ProposedFeatures.all);

function startupServer(port, wait) {
	const child = cp.fork(
		serverModule,
		['-serve', '--port', port],
		{
			stdio: [0, 1, 2, 'ipc'],
			execArgv: ['-max-old-space-size=8192'],
		} // To send messages on completion of startup
	);

	if (wait) {
		return new Promise((resolve, reject) => {
			child.on('message', function (msg) {
				if (msg.type === 'success') {
					child.unref();
					child.disconnect();
					resolve(msg);
				} else {
					reject(msg);
				}
			});
		});
	} else {
		child.unref();
		child.disconnect();
	}
}

connection.onInitialize(_params => {
	const capabilities: ServerCapabilities = {
		textDocumentSync: TextDocumentSyncKind.Incremental,
	};

	return { capabilities };
});

connection.onShutdown(_params => {});

const documents = new TextDocuments(TextDocument);
documents.listen(connection);
connection.listen();
