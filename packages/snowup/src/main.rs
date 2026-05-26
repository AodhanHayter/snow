mod flake;
mod flow;
mod host;

use anyhow::{Context, Result};
use clap::Parser;
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(version, about = "Flake update + rebuild driver (fzf-based selection)")]
struct Cli {
    /// Path to flake directory (default: $HOME/development/snow)
    #[arg(short = 'C', long)]
    flake_dir: Option<PathBuf>,

    /// Override host name (default: `hostname -s`)
    #[arg(long)]
    host: Option<String>,

    /// Only update the flake lock; skip rebuild
    #[arg(long)]
    no_rebuild: bool,

    /// Internal: render fzf preview for a TSV row
    #[arg(long, hide = true)]
    preview_row: Option<String>,
}

fn default_flake_dir() -> PathBuf {
    let home = std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("."));
    home.join("development/snow")
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    if let Some(line) = cli.preview_row {
        return flow::preview_row(&line);
    }

    let requested = cli.flake_dir.unwrap_or_else(default_flake_dir);
    let flake_dir = requested
        .canonicalize()
        .with_context(|| format!("flake-dir: {}", requested.display()))?;
    let lock_path = flake_dir.join("flake.lock");
    if !lock_path.exists() {
        anyhow::bail!("no flake.lock at {}", lock_path.display());
    }
    let host = match cli.host {
        Some(h) => h,
        None => host::hostname().unwrap_or_else(|_| "unknown".into()),
    };
    let os = host::detect_os();
    flow::run(flow::Config {
        flake_dir,
        host,
        os,
        no_rebuild: cli.no_rebuild,
    })
}
