use crate::flake::{self, Delta};
use crate::host::{self, Os};
use anyhow::{bail, Context, Result};
use chrono::{DateTime, Utc};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

pub struct Config {
    pub flake_dir: PathBuf,
    pub host: String,
    pub os: Os,
    pub no_rebuild: bool,
}

pub fn run(cfg: Config) -> Result<()> {
    let lock_path = cfg.flake_dir.join("flake.lock");
    let backup_lock = std::fs::read_to_string(&lock_path).context("read flake.lock")?;

    eprintln!(
        "snowup @ {} ({}) — {}",
        cfg.host,
        cfg.os.label(),
        cfg.flake_dir.display()
    );
    eprintln!("== step 1/3: nix flake update ==");

    let status = Command::new("nix")
        .args(["flake", "update"])
        .current_dir(&cfg.flake_dir)
        .status()
        .context("spawn nix flake update")?;
    if !status.success() {
        bail!("nix flake update failed: {status}");
    }

    let new_lock = std::fs::read_to_string(&lock_path).context("re-read flake.lock")?;
    let old = flake::parse(&backup_lock)?;
    let new = flake::parse(&new_lock)?;
    let deltas = flake::diff(&old, &new);
    if deltas.is_empty() {
        eprintln!("flake.lock already current — no inputs changed.");
        return Ok(());
    }

    eprintln!("== step 2/3: review ({} input(s) changed) ==", deltas.len());
    let selected = match select_with_fzf(&deltas)? {
        Some(s) => s,
        None => {
            std::fs::write(&lock_path, &backup_lock).context("restore flake.lock")?;
            eprintln!("cancelled. flake.lock restored.");
            return Ok(());
        }
    };
    if selected.is_empty() {
        std::fs::write(&lock_path, &backup_lock).context("restore flake.lock")?;
        eprintln!("nothing selected. flake.lock restored.");
        return Ok(());
    }

    if selected.len() != deltas.len() {
        apply_subset(&cfg.flake_dir, &backup_lock, &selected)?;
    } else {
        eprintln!("[snowup] keeping full lock update ({} input(s))", selected.len());
    }

    if cfg.no_rebuild {
        eprintln!("--no-rebuild set. lock updated.");
        return Ok(());
    }

    eprintln!("== step 3/3: rebuild ==");
    let mut rebuild = host::rebuild_command(cfg.os, &cfg.host, &cfg.flake_dir)?;
    let rebuild_status = rebuild.status().context("spawn rebuild")?;
    if !rebuild_status.success() {
        bail!("rebuild failed: {rebuild_status}");
    }
    eprintln!("rebuild succeeded.");
    Ok(())
}

fn apply_subset(flake_dir: &Path, backup_lock: &str, selected: &[String]) -> Result<()> {
    std::fs::write(flake_dir.join("flake.lock"), backup_lock)
        .context("restore backup lock before subset apply")?;
    for name in selected {
        eprintln!("[snowup] applying {name}");
        let status = Command::new("nix")
            .args(["flake", "update", name])
            .current_dir(flake_dir)
            .status()
            .with_context(|| format!("spawn nix flake update {name}"))?;
        if !status.success() {
            bail!("nix flake update {name} failed: {status}");
        }
    }
    Ok(())
}

const ROW_FIELDS: usize = 9;

fn row_for(d: &Delta) -> String {
    let age = d
        .age_days()
        .map(|n| format!("+{n}d"))
        .unwrap_or_else(|| "—".into());
    let when = d
        .new_modified
        .and_then(|t| DateTime::<Utc>::from_timestamp(t, 0))
        .map(|dt| dt.format("%Y-%m-%d").to_string())
        .unwrap_or_else(|| "—".into());
    let old_full = d.old_rev.clone().unwrap_or_else(|| "—".into());
    let new_full = d.new_rev.clone().unwrap_or_else(|| "—".into());
    let compare = d.compare_url().unwrap_or_default();
    let commit = d.commit_url().unwrap_or_default();
    [
        d.name.as_str(),
        &d.old_short(),
        &d.new_short(),
        &age,
        &when,
        &old_full,
        &new_full,
        &compare,
        &commit,
    ]
    .join("\t")
}

fn select_with_fzf(deltas: &[Delta]) -> Result<Option<Vec<String>>> {
    let exe = std::env::current_exe().context("current_exe")?;
    let preview_cmd = format!("{} --preview-row {{}}", shell_quote(&exe.to_string_lossy()));

    let mut child = Command::new("fzf")
        .args([
            "--multi",
            "--delimiter=\t",
            "--with-nth=1,2,3,4,5",
            "--header",
            "tab/shift-tab = toggle  enter = apply  ctrl-a = all  ctrl-d = none  esc = cancel",
            "--bind",
            "ctrl-a:select-all,ctrl-d:deselect-all",
            "--preview",
            &preview_cmd,
            "--preview-window=down:9:wrap",
            "--prompt",
            "inputs> ",
            "--no-mouse",
            "--ansi",
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .context("spawn fzf (is it installed?)")?;

    {
        let mut stdin = child.stdin.take().context("fzf stdin")?;
        for d in deltas {
            writeln!(stdin, "{}", row_for(d))?;
        }
    }
    let output = child.wait_with_output().context("wait fzf")?;
    match output.status.code() {
        Some(0) => {}
        Some(1) | Some(130) => return Ok(None),
        Some(c) => bail!("fzf exited with code {c}"),
        None => bail!("fzf killed by signal"),
    }
    let picked: Vec<String> = String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter_map(|l| l.split('\t').next().map(|s| s.to_string()))
        .filter(|s| !s.is_empty())
        .collect();
    Ok(Some(picked))
}

fn shell_quote(s: &str) -> String {
    if s.chars().all(|c| c.is_ascii_alphanumeric() || "/._-".contains(c)) {
        s.to_string()
    } else {
        format!("'{}'", s.replace('\'', "'\\''"))
    }
}

pub fn preview_row(line: &str) -> Result<()> {
    let parts: Vec<&str> = line.split('\t').collect();
    if parts.len() < 5 {
        bail!("malformed preview row");
    }
    let mut buf = Vec::<&str>::with_capacity(ROW_FIELDS);
    buf.extend_from_slice(&parts);
    while buf.len() < ROW_FIELDS {
        buf.push("");
    }
    let name = buf[0];
    let old_full = buf[5];
    let new_full = buf[6];
    let compare = buf[7];
    let commit = buf[8];
    let age = buf[3];
    let when = buf[4];

    println!("input:   {name}");
    println!("age:     {age}   modified: {when}");
    println!("old rev: {old_full}");
    println!("new rev: {new_full}");
    if !compare.is_empty() {
        println!();
        println!("compare: {compare}");
    } else if !commit.is_empty() {
        println!();
        println!("commit:  {commit}");
    }
    Ok(())
}
