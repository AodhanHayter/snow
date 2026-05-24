use anyhow::{Context, Result};
use serde::Deserialize;
use std::collections::HashMap;

#[derive(Debug, Clone, Deserialize)]
pub struct Lock {
    pub nodes: HashMap<String, Node>,
    pub root: String,
}

#[derive(Debug, Clone, Deserialize, Default)]
pub struct Node {
    #[serde(default)]
    pub inputs: Option<serde_json::Value>,
    #[serde(default)]
    pub locked: Option<Locked>,
}

#[derive(Debug, Clone, Deserialize, Default)]
pub struct Locked {
    #[serde(default)]
    pub rev: Option<String>,
    #[serde(default, rename = "lastModified")]
    pub last_modified: Option<i64>,
    #[serde(rename = "type", default)]
    pub kind: String,
    #[serde(default)]
    pub owner: Option<String>,
    #[serde(default)]
    pub repo: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
}

pub fn parse(s: &str) -> Result<Lock> {
    serde_json::from_str(s).context("parse flake.lock")
}

#[derive(Debug, Clone)]
pub struct Delta {
    pub name: String,
    pub old_rev: Option<String>,
    pub new_rev: Option<String>,
    pub old_modified: Option<i64>,
    pub new_modified: Option<i64>,
    pub locked: Option<Locked>,
}

fn root_inputs(lock: &Lock) -> HashMap<String, String> {
    let mut out = HashMap::new();
    let Some(root) = lock.nodes.get(&lock.root) else {
        return out;
    };
    let Some(inputs) = root.inputs.as_ref().and_then(|v| v.as_object()) else {
        return out;
    };
    for (name, v) in inputs {
        if let Some(s) = v.as_str() {
            out.insert(name.clone(), s.to_string());
        }
    }
    out
}

pub fn diff(old: &Lock, new: &Lock) -> Vec<Delta> {
    let old_inputs = root_inputs(old);
    let new_inputs = root_inputs(new);
    let mut names: Vec<&String> = new_inputs.keys().collect();
    names.sort();
    let mut deltas = vec![];
    for name in names {
        let new_id = &new_inputs[name];
        let new_locked = new.nodes.get(new_id).and_then(|n| n.locked.clone());
        let old_locked = old_inputs
            .get(name)
            .and_then(|id| old.nodes.get(id))
            .and_then(|n| n.locked.clone());

        let old_rev = old_locked.as_ref().and_then(|l| l.rev.clone());
        let new_rev = new_locked.as_ref().and_then(|l| l.rev.clone());
        let old_mod = old_locked.as_ref().and_then(|l| l.last_modified);
        let new_mod = new_locked.as_ref().and_then(|l| l.last_modified);

        let changed = match (&old_rev, &new_rev) {
            (Some(a), Some(b)) => a != b,
            (None, None) => old_mod != new_mod,
            _ => true,
        };
        if changed {
            deltas.push(Delta {
                name: name.clone(),
                old_rev,
                new_rev,
                old_modified: old_mod,
                new_modified: new_mod,
                locked: new_locked,
            });
        }
    }
    deltas
}

impl Delta {
    pub fn old_short(&self) -> String {
        short(self.old_rev.as_deref())
    }
    pub fn new_short(&self) -> String {
        short(self.new_rev.as_deref())
    }
    pub fn age_days(&self) -> Option<i64> {
        match (self.old_modified, self.new_modified) {
            (Some(o), Some(n)) => Some((n - o) / 86_400),
            _ => None,
        }
    }
    pub fn compare_url(&self) -> Option<String> {
        let l = self.locked.as_ref()?;
        if l.kind == "github" {
            let owner = l.owner.as_ref()?;
            let repo = l.repo.as_ref()?;
            let old = self.old_rev.as_ref()?;
            let new = self.new_rev.as_ref()?;
            return Some(format!(
                "https://github.com/{owner}/{repo}/compare/{old}...{new}"
            ));
        }
        None
    }
    pub fn commit_url(&self) -> Option<String> {
        let l = self.locked.as_ref()?;
        if l.kind == "github" {
            let owner = l.owner.as_ref()?;
            let repo = l.repo.as_ref()?;
            let rev = self.new_rev.as_ref()?;
            return Some(format!("https://github.com/{owner}/{repo}/commit/{rev}"));
        }
        l.url.clone()
    }
}

fn short(rev: Option<&str>) -> String {
    rev.map(|r| r.chars().take(8).collect::<String>())
        .unwrap_or_else(|| "—".into())
}
