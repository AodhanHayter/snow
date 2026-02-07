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

  # Marketplace submodule type
  marketplaceModule = types.submodule {
    options = {
      source = mkOption {
        type = types.submodule {
          options = {
            type = mkOpt types.str "github" "Source type: github, git, or local";
            url = mkOpt types.str "" "Repository URL (e.g., owner/repo)";
          };
        };
        description = "Marketplace source configuration";
      };
      flakeInput = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Flake input for Nix-managed (immutable) marketplace";
      };
    };
  };

  # Get last segment of marketplace name (e.g., "anthropics/claude-plugins-official" -> "claude-plugins-official")
  getMarketplaceName = name: lib.last (lib.splitString "/" name);

  # Marketplaces with flakeInput defined (Nix-managed via symlinks)
  nixManagedMarketplaces = filterAttrs (_: m: m.flakeInput != null) cfg.plugins.marketplaces;

  # Transform marketplaces to Claude known_marketplaces.json format
  toNativeFormat =
    name: m:
    let
      marketplaceName = getMarketplaceName name;
      localPath = "${homeDir}/.claude/plugins/marketplaces/${marketplaceName}";
    in
    lib.nameValuePair marketplaceName {
      source = {
        source = if m.source.type == "github" then "github" else m.source.type;
        repo = name;
      };
      installLocation = localPath;
      lastUpdated = "2025-01-01T00:00:00.000Z";
    };

  # Build known_marketplaces.json content
  knownMarketplaces =
    lib.listToAttrs (lib.mapAttrsToList toNativeFormat cfg.plugins.marketplaces)
    // optionalAttrs cfg.plugins.allowRuntimeInstall {
      "local" = {
        source = {
          source = "directory";
          path = "${homeDir}/.claude/plugins/local";
        };
        installLocation = "${homeDir}/.claude/plugins/marketplaces/local";
        lastUpdated = "2025-01-01T00:00:00.000Z";
        managedBy = "runtime";
      };
    };

  # Generate symlinks for Nix-managed marketplaces
  marketplaceSymlinks = lib.mapAttrs' (
    name: marketplace:
    lib.nameValuePair ".claude/plugins/marketplaces/${getMarketplaceName name}" {
      source = marketplace.flakeInput;
      force = true;
    }
  ) nixManagedMarketplaces;

  # Arc Raiders alert sound script
  arcAlertScript = pkgs.writeShellScript "play-arc-sound" ''
    SOUND_NAME="''${1:-arc-alert}"
    SOUND_DIR="${cfg.alerts.sounds}/share/sounds/arc-raiders"
    SOUND_FILE="$SOUND_DIR/''${SOUND_NAME}.wav"

    # Custom sound directory override
    CUSTOM_DIR="${homeDir}/.config/claude-code/sounds"
    if [ -f "$CUSTOM_DIR/''${SOUND_NAME}.wav" ]; then
      SOUND_FILE="$CUSTOM_DIR/''${SOUND_NAME}.wav"
    fi

    # Send tmux bell for visual notification in status bar
    if [ -n "$TMUX" ]; then
      printf '\a'
    fi

    # Play sound file if it exists
    if [ ! -f "$SOUND_FILE" ]; then
      exit 0
    fi

    case "$(uname -s)" in
      Darwin)
        afplay "$SOUND_FILE" 2>/dev/null &
        ;;
      Linux)
        if command -v paplay &>/dev/null; then
          paplay "$SOUND_FILE" 2>/dev/null &
        elif command -v pw-play &>/dev/null; then
          pw-play "$SOUND_FILE" 2>/dev/null &
        elif command -v aplay &>/dev/null; then
          aplay -q "$SOUND_FILE" 2>/dev/null &
        elif command -v play &>/dev/null; then
          play -q "$SOUND_FILE" 2>/dev/null &
        fi
        ;;
    esac

    exit 0
  '';

  # Base settings (without plugins)
  baseSettings = {
    statusLine = {
      type = "command";
      command = "bun x ccusage statusline";
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

        # devenv and direnv integration
        "Bash(devenv:*)"
        "Bash(direnv:*)"

      ];
      deny = [ ];
    };
    env = {
      CLAUDE_CODE_ENABLE_TELEMETRY = "0";
      CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      DIRENV_LOG_FORMAT = "";
      DIRENV_WARN_TIMEOUT = "0";
    };
    includeCoAuthoredBy = false;
  } // optionalAttrs cfg.alerts.enable {
    hooks = {
      Stop = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = "${arcAlertScript} arc-complete";
            }
          ];
        }
      ];
      Notification = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = "${arcAlertScript} arc-alert";
            }
          ];
        }
      ];
    };
  };

  # Merge enabled plugins into settings
  settings =
    baseSettings
    // optionalAttrs (cfg.plugins.enabled != { }) {
      enabledPlugins = cfg.plugins.enabled;
    };

  # Generate skill file entries from anthropics-skills input
  skillFiles = optionalAttrs cfg.skills.enable (
    listToAttrs (
      map (skillName: {
        name = ".claude/skills/${skillName}";
        value = {
          source = "${inputs.anthropics-skills}/skills/${skillName}";
        };
      }) cfg.skills.names
    )
  );
in
{
  options.modernage.cli-apps.claude-code = {
    enable = mkBoolOpt false "Whether or not to install and configure claude code.";

    plugins = {
      marketplaces = mkOption {
        type = types.attrsOf marketplaceModule;
        default = {
          "anthropics/claude-plugins-official" = {
            source = {
              type = "github";
              url = "anthropics/claude-plugins-official";
            };
            flakeInput = inputs.claude-plugins-official;
          };
          "anthropics/skills" = {
            source = {
              type = "github";
              url = "anthropics/skills";
            };
            flakeInput = inputs.anthropics-skills;
          };
          "kenryu42/cc-marketplace" = {
            source = {
              type = "github";
              url = "kenryu42/cc-marketplace";
            };
            flakeInput = inputs.cc-marketplace;
          };
          "sawyerhood/dev-browser" = {
            source = {
              type = "github";
              url = "sawyerhood/dev-browser";
            };
            flakeInput = inputs.dev-browser;
          };
          "AodhanHayter/claude-lsp-plugins" = {
            source = {
              type = "github";
              url = "AodhanHayter/claude-lsp-plugins";
            };
            flakeInput = inputs.claude-lsp-plugins;
          };
          "pzep1/xcode-build-skill" = {
            source = {
              type = "github";
              url = "pzep1/xcode-build-skill";
            };
            flakeInput = inputs.xcode-build-skill;
          };
          "conorluddy/xclaude-plugin" = {
            source = {
              type = "github";
              url = "conorluddy/xclaude-plugin";
            };
            flakeInput = inputs.xclaude-plugin;
          };
          "johnrogers/claude-swift-engineering" = {
            source = {
              type = "github";
              url = "johnrogers/claude-swift-engineering";
            };
            flakeInput = inputs.claude-swift-engineering;
          };
        };
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
        default = {
          "plugin-dev@claude-plugins-official" = true;
          "playground@claude-plugins-official" = true;
          "pr-review-toolkit@claude-plugins-official" = true;
          "claude-md-management@claude-plugins-official" = true;
          "code-simplifier@claude-plugins-official" = true;
          "commit-commands@claude-plugins-official" = true;
          "feature-dev@claude-plugins-official" = true;
          "frontend-design@claude-plugins-official" = true;
          "safety-net@cc-marketplace" = true;
          "dev-browser@dev-browser" = true;
          "nix-lsp@claude-lsp-plugins" = true;
          "python-lsp@claude-lsp-plugins" = true;
          "elixir-lsp@claude-lsp-plugins" = true;
          "swift-lsp@claude-lsp-plugins" = true;
          "xcode-build-skill@xcode-build-skill" = true;
          "xclaude-plugin@xclaude-plugin" = true;
          "swift-engineering@claude-swift-engineering" = true;
        };
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
      enable = mkBoolOpt false "Enable copying skills from anthropics-skills input";
      names = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Skill folder names to copy from anthropics/skills repo";
        example = [
          "document-skills"
          "example-skills"
        ];
      };
    };

    alerts = {
      enable = mkBoolOpt false "Enable Arc Raiders-inspired alert sounds via Claude Code hooks.";
      sounds = mkOption {
        type = types.package;
        default = pkgs.arc-sounds;
        description = ''
          Package providing alert sound files. Must contain .wav files at
          share/sounds/arc-raiders/. Override with custom sounds by placing
          .wav files in ~/.config/claude-code/sounds/ (takes priority).
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
      inherit settings;
      memory.source = ./CLAUDE.md;
      agentsDir = ./agents;
      commandsDir = ./commands;
      skillsDir = ./skills;
    };

    # Symlink Nix-managed marketplaces + skills
    home.file =
      marketplaceSymlinks
      // skillFiles
      // {
        # known_marketplaces.json - Claude needs this to find marketplaces
        ".claude/plugins/known_marketplaces.json" = {
          text = builtins.toJSON knownMarketplaces;
        };
      };

    # Create local plugins directory for runtime installs
    home.activation.claudePluginsSetup = mkIf cfg.plugins.allowRuntimeInstall (
      config.lib.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${homeDir}/.claude/plugins/local"
        run mkdir -p "${homeDir}/.claude/plugins/marketplaces/local"
      ''
    );

    home.packages = with pkgs; [
      claude-code-acp
    ];
  };
}
