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
    hoverProvider: true,
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

/**
 * Send a query to the Pyret server over its Unix-domain WebSocket.
 * @param portFile - Path to the Unix socket file
 * @param query - The query type to send (e.g. "jump-to-def", "diagnostics")
 * @param filePath - Path of the source file being queried
 * @param queryOptions - Additional options for the query (e.g. cursor position)
 * @param parseResponse - Callback that receives each non-echo message and
 *   should return a parsed result on success or `null` on failure
 * @returns The parsed response, or `null` if the query failed
 */
function sendQueryRequest<T>(
  portFile: string,
  query: string,
  filePath: string,
  queryOptions: object,
  parseResponse: (msg: any) => T | null,
): Promise<T | null> {
  return new Promise((resolve, reject) => {
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
            "base-dir": ".",
          }), // TODO: allow configuring default compileOptions
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

/**
 * Convert a Pyret source location to an LSP Range.
 * Pyret uses 1-based lines and 0-based columns;
 * LSP uses 0-based lines and 0-based columns.
 * @param startLine - 1-based start line from Pyret
 * @param startColumn - 0-based start column from Pyret
 * @param endLine - 1-based end line from Pyret
 * @param endColumn - 0-based end column from Pyret
 * @returns An LSP-compatible Range with 0-based positions
 */
function pyretLocToRange(
  startLine: number,
  startColumn: number,
  endLine: number,
  endColumn: number,
): { start: { line: number; character: number }; end: { line: number; character: number } } {
  return {
    start: { line: startLine - 1, character: startColumn },
    end: { line: endLine - 1, character: endColumn },
  };
}

// #region Query response types & parsers

interface JumpToDefResult {
  uri: string;
  range: { start: { line: number; character: number }; end: { line: number; character: number } };
}

function parseJumpToDef(msg: any): JumpToDefResult | null {
  if (msg.type === "jump-to-def-success") {
    return {
      uri: msg.uri,
      range: pyretLocToRange(
        msg["start-line"],
        msg["start-column"],
        msg["end-line"],
        msg["end-column"],
      ),
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

function parseCheckResponse(msg: any): CheckDiagnostic[] | null {
  if (msg.type === "check-success") {
    return msg.diagnostics ?? [];
  }
  if (msg.type === "check-failure") {
    return [];
  }
  return null;
}

function sendCheckRequest(
  portFile: string,
  filePath: string,
): Promise<CheckDiagnostic[] | null> {
  return sendQueryRequest(portFile, "check", filePath, {}, parseCheckResponse);
}

// #region LSP request handlers
// TODO: there is a lot of redundancy here, we should probably develop better
// abstractions here! especially for the off-by-one location issues (hacked in rn)

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
          range: pyretLocToRange(
            sym["start-line"],
            sym["start-column"],
            sym["end-line"],
            sym["end-column"],
          ),
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
  // TODO: fix these awful off-by-one errors!
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

    return result;
  } catch (err) {
    connection.console.error(`jump-to-def error: ${err}`);
    return null;
  }
});

interface HoverResult {
  ann: string;
  doc: string;
}

function parseHover(msg: any): HoverResult | null {
  if (msg.type === "hover-success") {
    return { ann: msg.ann, doc: msg.doc };
  }
  return null;
}

connection.onHover(async (params) => {
  const portFile = getSocketPath();
  if (!fs.existsSync(portFile)) {
    connection.console.error("Pyret server not running, cannot get hover info");
    return null;
  }

  const line = params.position.line + 1;
  const col = params.position.character + 1;
  const filePath = uriToFilePath(params.textDocument.uri);

  try {
    const result = await sendQueryRequest(
      portFile,
      "hover",
      filePath,
      { line, col },
      parseHover,
    );
    if (!result) return null;

    return {
      contents: {
        kind: "markdown",
        value: `ann:\`${result.ann}\`\n\ndoc: ${result.doc}`,
      },
    };
  } catch (err) {
    connection.console.error(`hover error: ${err}`);
    return null;
  }
});

const documents = new TextDocuments(TextDocument);

// Track the document version at last save per URI. VS Code triggers
// textDocument/diagnostic on didChange (before auto-save writes to disk), so
// we defer compilation until the saved version matches the current version.
const savedVersions = new Map<string, number>();

documents.onDidOpen((e) => {
  savedVersions.set(e.document.uri, e.document.version ?? 0);
});

documents.onDidSave((e) => {
  savedVersions.set(e.document.uri, e.document.version ?? 0);
  // Tell VS Code to re-request diagnostics now that the file is on disk.
  connection.languages.diagnostics.refresh();
});

connection.languages.diagnostics.on(async (params) => {
  const portFile = getSocketPath();
  if (!fs.existsSync(portFile)) {
    return { kind: DocumentDiagnosticReportKind.Full, items: [] };
  }

  const fileUri = params.textDocument.uri;

  // If the document has unsaved changes, the on-disk content is stale.
  // Return empty now; onDidSave will call refresh() once the file is saved.
  const doc = documents.get(fileUri);
  const savedVersion = savedVersions.get(fileUri) ?? doc?.version;
  if (doc && doc.version !== savedVersion) {
    return { kind: DocumentDiagnosticReportKind.Full, items: [] };
  }
  const filePath = uriToFilePath(fileUri)
  
  try {
    const rawDiagnostics = await sendCheckRequest(portFile, filePath);
    if (!rawDiagnostics) {
      return { kind: DocumentDiagnosticReportKind.Full, items: [] };
    }
    const items: Diagnostic[] = rawDiagnostics.map((d) => {
      const hasLoc = d["start-line"] !== undefined;
      return {
        severity: DiagnosticSeverity.Error,
        range: hasLoc
          ? pyretLocToRange(
              d["start-line"]!,
              d["start-column"]!,
              d["end-line"]!,
              d["end-column"]!,
            )
          : pyretLocToRange(1, 0, 1, 0),
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

documents.listen(connection);
connection.listen();
