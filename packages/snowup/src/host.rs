use anyhow::{Context, Result};
use std::path::Path;
use std::process::Command;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Os {
    Darwin,
    NixOS,
    Other,
}

impl Os {
    pub fn label(self) -> &'static str {
        match self {
            Os::Darwin => "darwin",
            Os::NixOS => "nixos",
            Os::Other => "other",
        }
    }
}

pub fn detect_os() -> Os {
    if cfg!(target_os = "macos") {
        Os::Darwin
    } else if Path::new("/etc/NIXOS").exists() {
        Os::NixOS
    } else {
        Os::Other
    }
}

pub fn hostname() -> Result<String> {
    let out = Command::new("hostname")
        .arg("-s")
        .output()
        .context("run hostname -s")?;
    let s = String::from_utf8_lossy(&out.stdout).trim().to_string();
    if s.is_empty() {
        anyhow::bail!("empty hostname");
    }
    Ok(s)
}

pub fn rebuild_command(os: Os, host: &str, flake_dir: &Path) -> Result<Command> {
    let flake = format!(".#{host}");
    let mut cmd = match os {
        Os::Darwin => {
            let mut c = Command::new("sudo");
            c.args(["darwin-rebuild", "switch", "--flake", &flake]);
            c
        }
        Os::NixOS => {
            let mut c = Command::new("doas");
            c.args(["nixos-rebuild", "switch", "--flake", &flake]);
            c
        }
        Os::Other => anyhow::bail!("unsupported OS for rebuild"),
    };
    cmd.current_dir(flake_dir);
    Ok(cmd)
}
