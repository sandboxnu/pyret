import { createConnection, ProposedFeatures } from "vscode-languageserver/node";

import {
  Connection,
  ServerCapabilities,
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
  const capabilities: ServerCapabilities = {
    textDocumentSync: TextDocumentSyncKind.Incremental,
    definitionProvider: true,
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

interface JumpToDefSuccess {
  uri: string;
  startLine: number;
  startColumn: number;
  endLine: number;
  endColumn: number;
}

function sendInfoRequest(
  portFile: string,
  filePath: string,
  line: number,
  col: number,
): Promise<JumpToDefSuccess | null> {
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
      const compileOptions = JSON.stringify({ program: filePath, line, col });
      client.send(JSON.stringify({ command: "info", compileOptions }));
    });

    client.on("message", (data: WebSocket.RawData) => {
      const msg = JSON.parse(data.toString());
      if (msg.type === "jump-to-def-success") {
        if (!settled) {
          settled = true;
          resolve({
            uri: msg.uri,
            startLine: msg["start-line"],
            startColumn: msg["start-column"],
            endLine: msg["end-line"],
            endColumn: msg["end-column"],
          });
        }
      } else if (msg.type === "jump-to-def-failure") {
        if (!settled) {
          settled = true;
          resolve(null);
        }
      } else if (msg.type === "echo-err") {
        connection.console.error("[pyret jump-to-def] " + msg.contents);
      } else if (msg.type === "echo-log") {
        connection.console.log("[pyret jump-to-def] " + msg.contents);
      }
    });

    client.on("close", () => {
      if (!settled) {
        settled = true;
        resolve(null);
      }
    });
  });
}

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

  // Strip file:// scheme to get a plain file path
  const fileUri = params.textDocument.uri;
  const filePath = fileUri.startsWith("file://")
    ? decodeURIComponent(fileUri.slice(7))
    : fileUri;

  try {
    const result = await sendInfoRequest(portFile, filePath, line, col);
    if (!result) {
      return null;
    }

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

const documents = new TextDocuments(TextDocument);
documents.listen(connection);
connection.listen();
