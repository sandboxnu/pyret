import * as vscode from "vscode";
import * as path from "path";
import { PyretCPOWebProvider, makeCommandHandler } from "./pyretCPOWebEditor";
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from "vscode-languageclient/node";

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(PyretCPOWebProvider.register(context));
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "pyret-parley.run-file",
      makeCommandHandler(context),
    ),
  );

  const serverModule = context.asAbsolutePath(
    path.join("..", "lsp-ts", "out", "server-node-tmp.js"),
  );
  const debugOptions = { execArgv: ["--nolazy", "--inspect=6009"] };
  const outputChannel = vscode.window.createOutputChannel(
    "Pyret Server",
  );
  const traceOutputChannel = vscode.window.createOutputChannel(
    "Pyret Language Server",
  );

  const serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: debugOptions,
    },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "pyret" }],
    synchronize: {
      fileEvents: vscode.workspace.createFileSystemWatcher("**/*.arr"),
    },
    outputChannel: outputChannel,
    traceOutputChannel: traceOutputChannel,
  };

  client = new LanguageClient(
    "pyret",
    "Pyret Language Server",
    serverOptions,
    clientOptions,
  );

  client.start();
  outputChannel.appendLine("Pyret Language Server started");
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
}
