import * as vscode from 'vscode';
import * as path from 'path';
import { PyretCPOWebProvider, makeCommandHandler } from './pyretCPOWebEditor';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext) {
	// Register our custom editor providers
	context.subscriptions.push(PyretCPOWebProvider.register(context));
    context.subscriptions.push(vscode.commands.registerCommand("pyret-parley.run-file", makeCommandHandler(context)));

  let serverModule = context.asAbsolutePath(path.join('server', 'out', 'server.js'));
  let debugOptions = { execArgv: ['--nolazy', '--inspect=6009'] };
  let outputChannel = vscode.window.createOutputChannel('Pyret Language Server');

  let serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: debugOptions
    }
  };

  let clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'pyret' }],
    synchronize: {
      fileEvents: vscode.workspace.createFileSystemWatcher('**/*.arr')
    },
    outputChannel: outputChannel,
    traceOutputChannel: outputChannel
  };

  client = new LanguageClient(
    'pyretLanguageServer',
    'Pyret Language Server',
    serverOptions,
    clientOptions
  );

  client.start();
  outputChannel.appendLine('Pyret Language Server started');
}

export function deactivate(): Thenable<void> | undefined {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
