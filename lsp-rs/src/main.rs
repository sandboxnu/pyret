use std::env;
use std::os::linux::process;
use std::path::{self, Path, PathBuf};

use tower_lsp::jsonrpc::{Error, Result};
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer, LspService, Server};

#[derive(Debug)]
struct Backend {
	client: Client,
	// compiler:
}

fn runtime_dir() -> std::io::Result<PathBuf> {
	if let Ok(dir) = env::var("XDG_RUNTIME_DIR") {
		return Ok(PathBuf::from(dir));
	}

	let uid = todo!();
	Ok(PathBuf::from(format!("/run/user/{uid}")))
}

#[tower_lsp::async_trait]
impl LanguageServer for Backend {
	async fn initialize(&self, params: InitializeParams) -> Result<InitializeResult> {
		let Some(parent_id) = params.process_id else {
			Err(Error::new(tower_lsp::jsonrpc::ErrorCode::ServerError(-1)))?
		};

		let mut cmd = tokio::process::Command::new("node")
			.arg("-serve")
			.arg("--port")
			.arg(format!("$XDG_RUNTIME_DIR/pyret-lsp-{}.sock", parent_id));
		Ok(InitializeResult {
			capabilities: ServerCapabilities {
				..Default::default()
			},
			..Default::default()
		})
	}

	async fn initialized(&self, _: InitializedParams) {
		self.client
			.log_message(MessageType::INFO, "server initialized!")
			.await;
	}

	async fn shutdown(&self) -> Result<()> {
		Ok(())
	}
}

#[tokio::main]
async fn main() {
	let stdin = tokio::io::stdin();
	let stdout = tokio::io::stdout();

	let pattern = std::env::args().nth(1).expect("no pattern given");

	let (service, socket) = LspService::new(|client| Backend { client });
	Server::new(stdin, stdout, socket).serve(service).await;
}
