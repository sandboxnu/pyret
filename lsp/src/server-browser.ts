import {
	BrowserMessageReader,
	BrowserMessageWriter,
	createConnection,
} from 'vscode-languageserver/browser';
import { setupServer } from './server-shared';

const messageReader = new BrowserMessageReader(globalThis);
const messageWriter = new BrowserMessageWriter(globalThis);

const connection = createConnection(messageReader, messageWriter);
setupServer(connection);
