import { createConnection, ProposedFeatures } from 'vscode-languageserver/node';
import { setupServer } from './server-shared';

const connection = createConnection(ProposedFeatures.all);
setupServer(connection);
