{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.claude-code;
  homeDir = config.home.homeDirectory;
  shared = config.modernage.coding-agents;

  extraKnownMarketplaces = agentConfig.mkClaudeExtraKnownMarketplaces cfg.plugins.marketplaces;
  marketplaceSymlinks = agentConfig.mkClaudeMarketplaceSymlinks cfg.plugins.marketplaces;

  statuslineScript = pkgs.runCommand "claude-statusline" { } ''
    substitute ${./statusline.sh} $out \
      --replace-fail "@PATH@" "${
        lib.makeBinPath (
          with pkgs;
          [
            jq
            git
            coreutils
            gawk
          ]
        )
      }"
    chmod +x $out
  '';

  # Base settings (without plugins)
  baseSettings = {
    statusLine = {
      type = "command";
      command = "${homeDir}/.claude/bin/claude-statusline";
      padding = 0;
    };
    permissions = {
      allow = [
        # Edit(**) covers Write/MultiEdit/NotebookEdit; Read(**) covers Grep/Glob
        "Read(**)"
        "Edit(**)"
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
        "Bash(nix eval:*)"

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

        # devenv integration
        "Bash(devenv:*)"

        # rtk meta commands only. Hook-rewritten commands are auto-allowed by
        # `rtk hook claude` itself; anything else (notably `rtk proxy <cmd>`,
        # which executes arbitrary commands) must prompt.
        "Bash(rtk gain)"
        "Bash(rtk gain:*)"
        "Bash(rtk discover)"
        "Bash(rtk discover:*)"
        "Bash(rtk --version)"

      ];
      deny = [ ];
    };
    env = shared.env;
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = agentConfig.mkBashGuardHooks shared.guards;
        }
      ];
    };
    includeCoAuthoredBy = false;
    editorMode = "vim";
    voiceEnabled = true;
    voice = {
      enabled = true;
      mode = "hold";
    };
  };

  # Merge enabled plugins and marketplace declarations into settings
  settings =
    baseSettings
    // optionalAttrs (cfg.plugins.enabled != { }) {
      enabledPlugins = cfg.plugins.enabled;
    }
    // optionalAttrs (cfg.plugins.marketplaces != { }) {
      inherit extraKnownMarketplaces;
    };

  # Render settings to a Nix-store JSON file. Seeded via activation as a
  # mutable copy at ~/.claude/settings.json so Claude Code commands like
  # /effort can write to it. Upstream HM symlink is bypassed by passing
  # settings = {} to programs.claude-code below.
  settingsJson = (pkgs.formats.json { }).generate "claude-code-settings.json" (
    settings
    // {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    }
  );

  skillFiles = agentConfig.mkSkillFiles ".claude/skills" cfg.skills;
in
{
  options.modernage.cli-apps.claude-code = {
    enable = mkBoolOpt false "Whether or not to install and configure claude code.";

    plugins = {
      marketplaces = mkOption {
        type = types.attrsOf agentConfig.marketplaceModule;
        default = shared.plugins.marketplaces;
        description = "Plugin marketplaces to register";
        example = literalExpression ''
          {
            "anthropics/claude-plugins-official" = {
              source = { type = "github"; url = "anthropics/claude-plugins-official"; };
              flakeInput = inputs.claude-plugins-official;
            };
          }
        '';
      };

      enabled = mkOption {
        type = types.attrsOf types.bool;
        default = shared.plugins.enabled;
        description = "Plugins to enable in format 'plugin-name@marketplace-name'";
        example = {
          "code-review@claude-plugins-official" = true;
          "frontend-design@claude-plugins-official" = true;
        };
      };

      allowRuntimeInstall = mkOption {
        type = types.bool;
        default = true;
        description = "Allow runtime plugin installation via /plugin command";
      };
    };

    skills = mkOption {
      type = types.attrsOf types.path;
      default = shared.skills.resolved;
      description = "Skills to symlink into ~/.claude/skills, as name -> directory.";
    };
  };

  config = mkIf cfg.enable {
    modernage.coding-agents.enable = true;

    # commandsDir/agentsDir are only set when the shared module has them: the
    # upstream option takes a path, and an empty (hence untracked) directory
    # never lands in the flake source.
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
      # Pass {} so upstream HM module skips creating ~/.claude/settings.json
      # symlink; we manage it ourselves via activation as a mutable copy.
      settings = { };
      # `memory.source`/`memory.text` renamed to `context` in HM 26.05
      context = shared.instructions;
    }
    // optionalAttrs (shared.commandsDir != null) {
      inherit (shared) commandsDir;
    }
    // optionalAttrs (shared.agentsDir != null) {
      inherit (shared) agentsDir;
    };

    # Symlink Nix-managed marketplaces + skills. Skills go through home.file
    # rather than programs.claude-code.skills so every entry (in-repo, flake
    # input, skill collection) lands the same way without colliding.
    home.file =
      marketplaceSymlinks
      // skillFiles
      // {
        # Stable path for the statusline so the mutable settings.json never
        # holds a /nix/store path that can be garbage-collected on rebuild.
        ".claude/bin/claude-statusline".source = statuslineScript;
      };

    # Seed ~/.claude/settings.json as a mutable copy of the Nix-rendered
    # settings. Only overwrites when the target is missing or a symlink to
    # /nix/store, so runtime edits (e.g. /effort, /model) survive HM rebuilds.
    home.activation.claudeSettingsSeed = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      target="${homeDir}/.claude/settings.json"
      run mkdir -p "${homeDir}/.claude"
      if [ ! -e "$target" ] || { [ -L "$target" ] && [[ "$(readlink "$target")" == /nix/store/* ]]; }; then
        run rm -f "$target"
        run install -m 0644 ${settingsJson} "$target"
      fi
    '';

    # Create local plugins directory for runtime installs
    home.activation.claudePluginsSetup = mkIf cfg.plugins.allowRuntimeInstall (
      config.lib.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${homeDir}/.claude/plugins/local"
        run mkdir -p "${homeDir}/.claude/plugins/marketplaces/local"
      ''
    );

    home.packages = with pkgs; [
      claude-agent-acp
      rtk
    ];
  };
}
