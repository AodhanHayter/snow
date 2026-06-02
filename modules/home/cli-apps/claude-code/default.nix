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
  homeDir = config.home.homeDirectory;
  agentDefaults = agentConfig.defaults inputs;

  extraKnownMarketplaces = agentConfig.mkClaudeExtraKnownMarketplaces cfg.plugins.marketplaces;
  marketplaceSymlinks = agentConfig.mkClaudeMarketplaceSymlinks cfg.plugins.marketplaces;

  notifyScript = pkgs.writeShellScript "claude-notify" ''
    [ -z "$TMUX" ] && exit 0
    INPUT=$(cat)
    TITLE=$(echo "$INPUT" | ${pkgs.jq}/bin/jq -r '.title // "Claude Code"')
    MESSAGE=$(echo "$INPUT" | ${pkgs.jq}/bin/jq -r '.message // "Notification"')
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\""
  '';

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

  # RTK token-saving PreToolUse hook. Rewrites Bash commands to `rtk <cmd>`
  # via `rtk rewrite`. Sourced from github:rtk-ai/rtk hooks/claude.
  rtkRewriteScript = pkgs.writeShellScript "rtk-rewrite" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.jq
        pkgs.rtk
      ]
    }:$PATH"
    ${builtins.readFile ./rtk-rewrite.sh}
  '';

  # Merge RTK awareness into Claude memory so Claude knows rtk exists and
  # which commands to invoke explicitly (rtk gain, rtk discover, ...).
  memoryText = builtins.readFile ./CLAUDE.md + "\n\n" + builtins.readFile ./rtk-awareness.md;

  # Base settings (without plugins)
  baseSettings = {
    statusLine = {
      type = "command";
      command = "${statuslineScript}";
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

        # rtk token-killer wrapper (auto-rewrites read-only cmds)
        "Bash(rtk:*)"

      ];
      deny = [ ];
    };
    env = agentDefaults.env;
    hooks = {
      Notification = [
        {
          hooks = [
            {
              type = "command";
              command = "${notifyScript}";
            }
          ];
        }
      ];
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${rtkRewriteScript}";
            }
            {
              type = "command";
              command = "dcg";
            }
          ];
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

  skillFiles = agentConfig.mkSkillFiles ".claude/skills" cfg.skills.sources;
in
{
  options.modernage.cli-apps.claude-code = {
    enable = mkBoolOpt false "Whether or not to install and configure claude code.";

    plugins = {
      marketplaces = mkOption {
        type = types.attrsOf agentConfig.marketplaceModule;
        default = agentDefaults.plugins.marketplaces;
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
        default = agentDefaults.plugins.claudeEnabled;
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

    skills = {
      sources = mkOption {
        type = types.attrsOf agentConfig.skillSourceModule;
        default = agentDefaults.skills.sources;
        description = "External skill sources to symlink into ~/.claude/skills";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
      # Pass {} so upstream HM module skips creating ~/.claude/settings.json
      # symlink; we manage it ourselves via activation as a mutable copy.
      settings = { };
      # `memory.source`/`memory.text` renamed to `context` in HM 26.05
      context = memoryText;

      commandsDir = ./commands;
    };

    # Symlink Nix-managed marketplaces + skills
    home.file =
      marketplaceSymlinks
      // skillFiles
      // {
        ".claude/skills/herdr".source = pkgs.runCommand "herdr-skill" { } ''
          mkdir -p $out
          cp ${inputs.herdr-skill}/SKILL.md $out/SKILL.md
        '';
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
