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

  # Build extraKnownMarketplaces for settings.json
  extraKnownMarketplaces = lib.mapAttrs' (
    name: m:
    lib.nameValuePair (getMarketplaceName name) {
      source = {
        source = if m.source.type == "github" then "github" else m.source.type;
        repo = name;
      };
    }
  ) cfg.plugins.marketplaces;

  # Generate symlinks for Nix-managed marketplaces
  marketplaceSymlinks = lib.mapAttrs' (
    name: marketplace:
    lib.nameValuePair ".claude/plugins/marketplaces/${getMarketplaceName name}" {
      source = marketplace.flakeInput;
      force = true;
    }
  ) nixManagedMarketplaces;

  notifyScript = pkgs.writeShellScript "claude-notify" ''
    [ -z "$TMUX" ] && exit 0
    INPUT=$(cat)
    TITLE=$(echo "$INPUT" | ${pkgs.jq}/bin/jq -r '.title // "Claude Code"')
    MESSAGE=$(echo "$INPUT" | ${pkgs.jq}/bin/jq -r '.message // "Notification"')
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\""
  '';

  statuslineScript = pkgs.runCommand "claude-statusline" { } ''
    substitute ${./statusline.sh} $out \
      --replace-fail "@PATH@" "${lib.makeBinPath (with pkgs; [ jq curl git coreutils gnused gawk ])}"
    chmod +x $out
  '';

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
              command = "dcg";
            }
          ];
        }
      ];
    };
    includeCoAuthoredBy = false;
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
          "dev-browser@dev-browser" = true;
          "nix-lsp@claude-lsp-plugins" = true;
          "python-lsp@claude-lsp-plugins" = true;
          "elixir-lsp@claude-lsp-plugins" = true;
          "swift-lsp@claude-lsp-plugins" = true;
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
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
      inherit settings;
      memory.source = ./CLAUDE.md;

      commandsDir = ./commands;
      skillsDir = ./skills;
    };

    # Symlink Nix-managed marketplaces + skills
    home.file = marketplaceSymlinks // skillFiles;

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
