import { createConnection, ProposedFeatures } from "vscode-languageserver/node";

import {
  Diagnostic,
  DiagnosticSeverity,
  DocumentDiagnosticReportKind,
  ServerCapabilities,
  SymbolInformation,
  SymbolKind,
  TextDocuments,
  TextDocumentSyncKind,
} from "vscode-languageserver";
import { TextDocument } from "vscode-languageserver-textdocument";
import * as childProcess from "child_process";
import * as path from "path";
import * as fs from "fs";
import * as os from "os";
import WebSocket from "ws";

const connection = createConnection(ProposedFeatures.all);

// Pyret server management
const compilerPath = path.join(
  __dirname,
  "..",
  "..",
  "lang",
  "build",
  "phaseA",
  "pyret.jarr",
);
let pyretServerProcess: childProcess.ChildProcess | null = null;

function getSocketPath(): string {
  const name = "parley-lsp-" + os.userInfo().username;
  const dir = path.join(os.tmpdir(), name);

  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  return path.join(dir, `comm-${process.pid}.sock`);
}

function uriToFilePath(uri: string): string {
  return uri.startsWith("file://") ? decodeURIComponent(uri.slice(7)) : uri;
}

function startPyretServer(portFile: string): Promise<void> {
  return new Promise((resolve, reject) => {
    connection.console.log(
      `Starting Pyret server with compiler at: ${compilerPath}`,
    );

    if (!fs.existsSync(compilerPath)) {
      reject(new Error(`Compiler not found at ${compilerPath}`));
      return;
    }

    const child = childProcess.fork(
      compilerPath,
      ["-serve", "--port", portFile],
      {
        stdio: [0, 1, 2, "ipc"],
        execArgv: ["-max-old-space-size=8192"],
      },
    );

    pyretServerProcess = child;

    child.on("message", (msg: any) => {
      if (msg.type === "success") {
        connection.console.log("Pyret server started successfully");
        child.unref();
        child.disconnect();
        resolve();
      } else {
        reject(msg);
      }
    });

    child.on("error", (err) => {
      connection.console.error(`Pyret server error: ${err.message}`);
      reject(err);
    });

    child.on("exit", (code, signal) => {
      connection.console.log(
        `Pyret server exited with code ${code}, signal ${signal}`,
      );
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

connection.onInitialize(async (_params) => {
  // NOTE(lsp): Register new LSP capabilities here (e.g. hoverProvider: true)
  const capabilities: ServerCapabilities = {
    textDocumentSync: TextDocumentSyncKind.Incremental,
    definitionProvider: true,
    documentSymbolProvider: true,
    diagnosticProvider: {
      interFileDependencies: false,
      workspaceDiagnostics: false,
    },
  };

  const portFile = getSocketPath();
  try {
    if (!fs.existsSync(portFile)) {
      await startPyretServer(portFile);
    } else {
      connection.console.log("Pyret server already running at " + portFile);
    }
  } catch (err) {
    connection.console.error(`Failed to start Pyret server: ${err}`);
  }

  return { capabilities };
});

connection.onShutdown((_params) => {
  const portFile = getSocketPath();
  shutdownPyretServer(portFile);
});

// NOTE(lsp): To add a new LSP feature:
// 1. Add a parseResponse callback for the new query type (following the pattern below)
// 2. Add a connection.on* handler at the bottom that calls sendQueryRequest
// 3. Register the capability in onInitialize
// 4. Add an query case in server.arr's query handler
// 5. Add the Pyret-side logic in query.arr

/** Send a query to the Pyret server over its Unix-domain WebSocket.
 *  `parseResponse` receives each non-echo message and should return a parsed
 *  result on success or `null` on failure/unrecognized messages. */
function sendQueryRequest<T>(
  portFile: string,
  query: string,
  filePath: string,
  queryOptions: object,
  parseResponse: (msg: any) => T | null,
): Promise<T | null> {
  return new Promise((resolve, reject) => {
    // FIXME: close client
    const client = new WebSocket("ws+unix://" + portFile);
    let settled = false;

    const settle = (value: T | null) => {
      if (!settled) {
        settled = true;
        client.close();
        resolve(value);
      }
    };

    client.on("error", (err) => {
      if (!settled) {
        settled = true;
        reject(err);
      }
    });

    client.on("open", () => {
      client.send(
        JSON.stringify({
          command: "query",
          query,
          compileOptions: JSON.stringify({
            program: filePath,
            "base-dir": ".", // TODO: allow configuring default compileOptions
          }),
          queryOptions: JSON.stringify(queryOptions),
        }),
      );
    });

    client.on("message", (data: WebSocket.RawData) => {
      const msg = JSON.parse(data.toString());
      if (msg.type === "echo-err") {
        connection.console.error(`[pyret ${query}] ${msg.contents}`);
      } else if (msg.type === "echo-log") {
        connection.console.log(`[pyret ${query}] ${msg.contents}`);
      } else {
        settle(parseResponse(msg));
      }
    });

    client.on("close", () => settle(null));
  });
}

// --- Query response types & parsers ---

interface JumpToDefSuccess {
  uri: string;
  startLine: number;
  startColumn: number;
  endLine: number;
  endColumn: number;
}

function parseJumpToDef(msg: any): JumpToDefSuccess | null {
  if (msg.type === "jump-to-def-success") {
    return {
      uri: msg.uri,
      startLine: msg["start-line"],
      startColumn: msg["start-column"],
      endLine: msg["end-line"],
      endColumn: msg["end-column"],
    };
  }
  return null;
}

interface DocumentSymbolItem {
  name: string;
  kind: string;
  "start-line": number;
  "start-column": number;
  "end-line": number;
  "end-column": number;
}

function parseDocumentSymbols(msg: any): DocumentSymbolItem[] | null {
  if (msg.type === "document-symbols-success") {
    return msg.symbols as DocumentSymbolItem[];
  }
  return null;
}

function pyretKindToSymbolKind(kind: string): SymbolKind {
  switch (kind) {
    case "vb-letrec":
      return SymbolKind.Function;
    case "vb-let":
      return SymbolKind.Constant;
    case "vb-var":
      return SymbolKind.Variable;
    case "type":
      return SymbolKind.Class;
    case "module":
      return SymbolKind.Module;
    default:
      return SymbolKind.Variable;
  }
}

interface CheckDiagnostic {
  message: string;
  "start-line"?: number;
  "start-column"?: number;
  "end-line"?: number;
  "end-column"?: number;
}

function sendCheckRequest(
  portFile: string,
  filePath: string,
): Promise<CheckDiagnostic[]> {
  return new Promise((resolve, reject) => {
    const client = new WebSocket("ws+unix://" + portFile);
    let settled = false;

    client.on("error", (err) => {
      if (!settled) {
        settled = true;
        reject(err);
      }
    });

    client.on("open", () => {
      client.send(
        JSON.stringify({
          command: "query",
          query: "check",
          compileOptions: JSON.stringify({ program: filePath }),
          queryOptions: JSON.stringify({}),
        }),
      );
    });

    client.on("message", (data: WebSocket.RawData) => {
      const msg = JSON.parse(data.toString());
      if (msg.type === "check-success") {
        if (!settled) {
          settled = true;
          resolve(msg.diagnostics ?? []);
        }
      } else if (msg.type === "check-failure") {
        if (!settled) {
          settled = true;
          resolve([]);
        }
      } else if (msg.type === "echo-err") {
        connection.console.error("[pyret check] " + msg.contents);
      } else if (msg.type === "echo-log") {
        connection.console.log("[pyret check] " + msg.contents);
      }
    });

    client.on("close", () => {
      if (!settled) {
        settled = true;
        resolve([]);
      }
    });
  });
}

// --- LSP request handlers ---

connection.onDocumentSymbol(async (params) => {
  const portFile = getSocketPath();
  if (!fs.existsSync(portFile)) {
    connection.console.error(
      "Pyret server not running, cannot get document symbols",
    );
    return null;
  }

  const filePath = uriToFilePath(params.textDocument.uri);

  try {
    const symbols = await sendQueryRequest(
      portFile,
      "document-symbols",
      filePath,
      {},
      parseDocumentSymbols,
    );
    if (!symbols) return null;

    return symbols.map(
      (sym): SymbolInformation => ({
        name: sym.name,
        kind: pyretKindToSymbolKind(sym.kind),
        location: {
          uri: params.textDocument.uri,
          range: {
            start: {
              line: sym["start-line"] - 1,
              character: sym["start-column"],
            },
            end: {
              line: sym["end-line"] - 1,
              character: sym["end-column"],
            },
          },
        },
      }),
    );
  } catch (err) {
    connection.console.error(`document-symbols error: ${err}`);
    return null;
  }
});

connection.onDefinition(async (params) => {
  const portFile = getSocketPath();
  if (!fs.existsSync(portFile)) {
    connection.console.error(
      "Pyret server not running, cannot jump to definition",
    );
    return null;
  }

  // LSP positions are 0-indexed; Pyret srclocs are 1-indexed
  const line = params.position.line + 1;
  const col = params.position.character + 1;
  const filePath = uriToFilePath(params.textDocument.uri);

  try {
    const result = await sendQueryRequest(
      portFile,
      "jump-to-def",
      filePath,
      { line, col },
      parseJumpToDef,
    );
    if (!result) return null;

    return {
      uri: result.uri,
      range: {
        start: {
          line: result.startLine - 1,
          character: result.startColumn,
        },
        end: { line: result.endLine - 1, character: result.endColumn },
      },
    };
  } catch (err) {
    connection.console.error(`jump-to-def error: ${err}`);
    return null;
  }
});

connection.languages.diagnostics.on(async (params) => {
  const portFile = getSocketPath();
  if (!fs.existsSync(portFile)) {
    return { kind: DocumentDiagnosticReportKind.Full, items: [] };
  }

  const fileUri = params.textDocument.uri;
  const filePath = fileUri.startsWith("file://")
    ? decodeURIComponent(fileUri.slice(7))
    : fileUri;

  try {
    const rawDiagnostics = await sendCheckRequest(portFile, filePath);
    const items: Diagnostic[] = rawDiagnostics.map((d) => {
      const hasLoc = d["start-line"] !== undefined;
      return {
        severity: DiagnosticSeverity.Error,
        range: {
          start: {
            line: hasLoc ? d["start-line"]! - 1 : 0,
            character: hasLoc ? d["start-column"]! : 0,
          },
          end: {
            line: hasLoc ? d["end-line"]! - 1 : 0,
            character: hasLoc ? d["end-column"]! : 0,
          },
        },
        message: d.message,
        source: "pyret",
      };
    });
    return { kind: DocumentDiagnosticReportKind.Full, items };
  } catch (err) {
    connection.console.error(`diagnostic error: ${err}`);
    return { kind: DocumentDiagnosticReportKind.Full, items: [] };
  }
});

const documents = new TextDocuments(TextDocument);
documents.listen(connection);
connection.listen();
