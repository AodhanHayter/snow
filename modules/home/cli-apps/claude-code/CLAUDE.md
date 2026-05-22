In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

When working in a repository use the agentlocal directory to store ephemeral files.

## Jira

- When given or asked about a Jira ticket use the `acli` cli tool to retrieve its contents:

    # Examples
    # command format:
    # $ acli jira workitem view [key] [flags]

    # View work item with work item keys
    $ acli jira workitem view KEY-123

    # View work item by reading work item keys from a JSON file
    $ acli jira workitem view KEY-123 --json

    # View work item with work item keys and a list of field to return
    $ acli jira workitem view KEY-123 --fields summary,comment

## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI.

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

## Shell

- `rm` is aliased to interactive mode; use `rm -f` to bypass in scripts.

## Skills

Skills are directories in `skills/` with a `SKILL.md` entrypoint:
```
skills/<skill-name>/SKILL.md
```

Format:
```md
---
name: skill-name
description: Brief description for skill discovery
---
# Skill content...
```

Module option: `skillsDir = ./skills;`

## External Skills (SKILL.md at repo root + extra files)

`skills.sources` expects skill folders, not root-level SKILL.md. For upstream repos with SKILL.md at root, wrap flake input to extract only SKILL.md:

```nix
home.file.".claude/skills/<name>".source = pkgs.runCommand "<name>-skill" { } ''
  mkdir -p $out
  cp ${inputs.<input>}/SKILL.md $out/SKILL.md
'';
```

Refresh via `nix flake update <input>` — derivation re-runs on input change.

## Plugin Marketplaces

- Attr key in `cfg.plugins.marketplaces` MUST equal marketplace.json `name` field (Claude Code uses it as marketplace identity; also used as symlink dir under `~/.claude/plugins/marketplaces/`).
- `source.url` holds GitHub owner/repo path; used as `repo` in `extraKnownMarketplaces`.
