mod flake;
mod host;
mod runner;
mod tui;

use anyhow::{Context, Result};
use clap::Parser;
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(version, about = "TUI for reviewing flake.lock updates and rebuilding the host")]
struct Cli {
    /// Path to flake directory (default: cwd)
    #[arg(short = 'C', long, default_value = ".")]
    flake_dir: PathBuf,

    /// Override host name (default: `hostname -s`)
    #[arg(long)]
    host: Option<String>,

    /// Only update the flake lock; skip rebuild
    #[arg(long)]
    no_rebuild: bool,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let flake_dir = cli
        .flake_dir
        .canonicalize()
        .with_context(|| format!("flake-dir: {}", cli.flake_dir.display()))?;
    let lock_path = flake_dir.join("flake.lock");
    if !lock_path.exists() {
        anyhow::bail!("no flake.lock at {}", lock_path.display());
    }
    let host = match cli.host {
        Some(h) => h,
        None => host::hostname().unwrap_or_else(|_| "unknown".into()),
    };
    let os = host::detect_os();
    tui::run(tui::Config {
        flake_dir,
        host,
        os,
        no_rebuild: cli.no_rebuild,
    })
}
