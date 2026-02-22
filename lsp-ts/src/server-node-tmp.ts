import { createConnection, ProposedFeatures } from 'vscode-languageserver/node';

import {
	Connection,
	ServerCapabilities,
	TextDocuments,
	TextDocumentSyncKind,
} from 'vscode-languageserver';
import { TextDocument } from 'vscode-languageserver-textdocument';
import * as childProcess from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

const connection = createConnection(ProposedFeatures.all);

// Pyret server management
const compilerPath = path.join(__dirname, '..', '..', 'lang', 'build', 'phaseA', 'pyret.jarr');
let pyretServerProcess: childProcess.ChildProcess | null = null;

function getSocketPath(): string {
	const name = 'parley-lsp-' + os.userInfo().username;
	const dir = path.join(os.tmpdir(), name);

	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir, { recursive: true });
	}

	return path.join(dir, 'comm.sock');
}

function startPyretServer(portFile: string): Promise<void> {
	return new Promise((resolve, reject) => {
		connection.console.log(`Starting Pyret server with compiler at: ${compilerPath}`);

		if (!fs.existsSync(compilerPath)) {
			reject(new Error(`Compiler not found at ${compilerPath}`));
			return;
		}

		const child = childProcess.fork(compilerPath, ['-serve', '--port', portFile], {
			stdio: [0, 1, 2, 'ipc'],
			execArgv: ['-max-old-space-size=8192'],
		});

		pyretServerProcess = child;

		child.on('message', (msg: any) => {
			if (msg.type === 'success') {
				connection.console.log('Pyret server started successfully');
				child.unref();
				child.disconnect();
				resolve();
			} else {
				reject(msg);
			}
		});

		child.on('error', err => {
			connection.console.error(`Pyret server error: ${err.message}`);
			reject(err);
		});

		child.on('exit', (code, signal) => {
			connection.console.log(`Pyret server exited with code ${code}, signal ${signal}`);
			pyretServerProcess = null;
		});
	});
}

function shutdownPyretServer(portFile: string): void {
	if (fs.existsSync(portFile)) {
		try {
			fs.unlinkSync(portFile);
		} catch (e) {
			connection.console.warn(`Could not remove port file: ${e}`);
		}
	}

	if (pyretServerProcess) {
		pyretServerProcess.kill();
		pyretServerProcess = null;
	}
}

connection.onInitialize(async _params => {
	const capabilities: ServerCapabilities = {
		textDocumentSync: TextDocumentSyncKind.Incremental,
		definitionProvider: true,
	};

	const portFile = getSocketPath();
	try {
		if (!fs.existsSync(portFile)) {
			await startPyretServer(portFile);
		} else {
			connection.console.log('Pyret server already running at ' + portFile);
		}
	} catch (err) {
		connection.console.error(`Failed to start Pyret server: ${err}`);
	}

	return { capabilities };
});

connection.onShutdown(_params => {
	const portFile = getSocketPath();
	shutdownPyretServer(portFile);
});

connection.onDefinition((params, token, workdown, result) => {
	return { uri: params.textDocument.uri, range: { start: { line: 0, character: 0 }, end: { line: 0, character: 0 } } };
});

const documents = new TextDocuments(TextDocument);
documents.listen(connection);
connection.listen();
