{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.claude-code;

  # Skill type definition
  skillType = types.submodule {
    options = {
      name = mkOpt types.str "" "Skill name (used for directory)";
      description = mkOpt types.str "" "Skill description for semantic matching";
      content = mkOpt types.str "" "Skill markdown content (without frontmatter)";
      allowedTools = mkOpt (types.nullOr types.str) null "Comma-separated allowed tools";
      model = mkOpt (types.nullOr types.str) null "Model override";
    };
  };

  # External skill source type
  externalSkillsType = types.submodule {
    options = {
      src = mkOpt types.path "" "Path to plugin repo (from inputs)";
      plugins = mkOpt (types.nullOr (types.listOf types.str)) null "List of plugins to load (null = all)";
      blacklist = mkOpt (types.listOf types.str) [] "Skill names to exclude";
    };
  };

  # Load external skills
  externalSkills = lib.flatten (
    map (ext: lib.modernage.skills.loadPluginSkills {
      inherit (ext) src plugins blacklist;
    }) cfg.externalSkills
  );

  # Merge all skills (local wins on collision)
  allSkills =
    let
      localNames = map (s: s.name) cfg.skills;
      filteredExternal = filter (s: !(elem s.name localNames)) externalSkills;
    in
    cfg.skills ++ filteredExternal;

  # Generate skill files
  skillFiles = lib.modernage.skills.mkSkillFiles allSkills;

  settings = {
    statusLine = {
      type = "command";
      command = "bunx ccusage statusline";
      padding = 0;
    };
    permissions = {
      allow = [
        "Read(**)"
        "Edit(**)"
        "MultiEdit(**)"
        "Write(**)"
        "Glob(**)"
        "Grep(**)"
        "LS(**)"
        "WebSearch"
        "TodoRead(**)"
        "TodoWrite(**)"
        "Task(**)"

        # Nix commands
        "Bash(nix flake check)"
        "Bash(nix build:*)"
        "Bash(nix fmt)"
        "Bash(nix develop)"

        # Read-only file operations
        "Bash(ls:*)"
        "Bash(cat:*)"
        "Bash(head:*)"
        "Bash(tail:*)"
        "Bash(grep:*)"
        "Bash(rg:*)"
        "Bash(fd:*)"
        "Bash(find:*)"
        "Bash(which:*)"
        "Bash(pwd)"
        "Bash(whoami)"
        "Bash(uname:*)"

        # Git read operations
        "Bash(git status:*)"
        "Bash(git log:*)"
        "Bash(git diff:*)"
        "Bash(git branch:*)"
        "Bash(git remote:*)"
        "Bash(git show:*)"

        # Package manager read operations
        "Bash(npm list:*)"
        "Bash(yarn list:*)"
        "Bash(cargo tree)"
        "Bash(pip list)"
        "Bash(gem list)"

        # System information
        "Bash(date)"
        "Bash(echo:*)"
        "Bash(env)"
        "Bash(printenv)"
        "Bash(locale:*)"

        # File analysis
        "Bash(file:*)"
        "Bash(wc:*)"
        "Bash(du:*)"
        "Bash(tree:*)"
        "Bash(stat:*)"

        # Text processing
        "Bash(sed:*)"
        "Bash(awk:*)"
        "Bash(sort:*)"
        "Bash(uniq:*)"
        "Bash(cut:*)"
        "Bash(tr:*)"

        # JSON/YAML tools
        "Bash(jq:*)"
        "Bash(yq:*)"

        # devenv and direnv integration
        "Bash(devenv:*)"
        "Bash(direnv:*)"

        # Beads - AI agent issue tracker
        "Bash(bd:*)"
      ];
      deny = [ ];
    };
    env = {
      CLAUDE_CODE_ENABLE_TELEMETRY = "0";
      CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
      # Ensure direnv state is inherited by claude-code subprocesses
      DIRENV_LOG_FORMAT = "";
      # Force direnv to always apply in subprocesses
      DIRENV_WARN_TIMEOUT = "0";
    };
    includeCoAuthoredBy = false;
  };
in
{
  options.modernage.cli-apps.claude-code = {
    enable = mkBoolOpt false "Whether or not to install and configure claude code.";
    skills = mkOpt (types.listOf skillType) [] "Local skill definitions";
    externalSkills = mkOpt (types.listOf externalSkillsType) [
      {
        src = inputs.claude-code-elixir;
        plugins = null; # all plugins
        blacklist = ["phoenix-ecto-thinking"];
      }
    ] "External skill sources (plugin repos)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
      claude-code-acp
    ];

    home.file = {
      ".claude/CLAUDE.md".source = ./CLAUDE.md;
      ".claude/settings.json" = {
        text = builtins.toJSON settings;
      };
      ".claude/agents" = {
        source = ./agents;
        recursive = true;
      };
      ".claude/commands" = {
        source = ./commands;
        recursive = true;
      };
    } // skillFiles;
  };
}
