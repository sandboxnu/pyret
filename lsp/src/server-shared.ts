import {
	Connection,
	ServerCapabilities,
	TextDocuments,
	TextDocumentSyncKind,
} from 'vscode-languageserver';
import { TextDocument } from 'vscode-languageserver-textdocument';

export function setupServer(connection: Connection) {
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
}
