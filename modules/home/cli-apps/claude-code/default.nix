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

  notifyScript = pkgs.writeShellScript "claude-notify" ''
    [ -z "$TMUX" ] && exit 0
    INPUT=$(cat)
    TITLE=$(echo "$INPUT" | ${pkgs.jq}/bin/jq -r '.title // "Claude Code"')
    MESSAGE=$(echo "$INPUT" | ${pkgs.jq}/bin/jq -r '.message // "Notification"')
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\""
  '';

  statuslineScript = pkgs.writeShellScript "claude-statusline" ''
    set -f
    export PATH="${lib.makeBinPath (with pkgs; [ jq curl git coreutils gnused gawk ])}:$PATH"

    input=$(cat)
    if [ -z "$input" ]; then
      printf "Claude"
      exit 0
    fi

    # ── Colors ──────────────────────────────────────────────
    blue='\033[38;2;0;153;255m'
    orange='\033[38;2;255;176;85m'
    green='\033[38;2;0;175;80m'
    cyan='\033[38;2;86;182;194m'
    red='\033[38;2;255;85;85m'
    yellow='\033[38;2;230;200;0m'
    white='\033[38;2;220;220;220m'
    magenta='\033[38;2;180;140;255m'
    dim='\033[2m'
    reset='\033[0m'

    sep=" ''${dim}│''${reset} "

    # ── Helpers ─────────────────────────────────────────────
    format_tokens() {
      local num=$1
      if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
      elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
      else
        printf "%d" "$num"
      fi
    }

    color_for_pct() {
      local pct=$1
      if [ "$pct" -ge 90 ]; then printf "$red"
      elif [ "$pct" -ge 70 ]; then printf "$yellow"
      elif [ "$pct" -ge 50 ]; then printf "$orange"
      else printf "$green"
      fi
    }

    build_bar() {
      local pct=$1
      local width=$2
      [ "$pct" -lt 0 ] 2>/dev/null && pct=0
      [ "$pct" -gt 100 ] 2>/dev/null && pct=100

      local filled=$(( pct * width / 100 ))
      local empty=$(( width - filled ))
      local bar_color
      bar_color=$(color_for_pct "$pct")

      local filled_str="" empty_str=""
      for ((i=0; i<filled; i++)); do filled_str+="●"; done
      for ((i=0; i<empty; i++)); do empty_str+="○"; done

      printf "''${bar_color}''${filled_str}''${dim}''${empty_str}''${reset}"
    }

    iso_to_epoch() {
      local iso_str="$1"
      local epoch
      epoch=$(date -d "''${iso_str}" +%s 2>/dev/null)
      if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
      fi

      local stripped="''${iso_str%%.*}"
      stripped="''${stripped%%Z}"
      stripped="''${stripped%%+*}"
      stripped="''${stripped%%-[0-9][0-9]:[0-9][0-9]}"

      if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
      else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
      fi

      if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
      fi

      return 1
    }

    format_reset_time() {
      local iso_str="$1"
      local style="$2"
      [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return

      local epoch
      epoch=$(iso_to_epoch "$iso_str")
      [ -z "$epoch" ] && return

      case "$style" in
        time)
          date -j -r "$epoch" +"%l:%M%p" 2>/dev/null | sed 's/^ //; s/\.//g' | tr '[:upper:]' '[:lower:]' || \
          date -d "@$epoch" +"%l:%M%P" 2>/dev/null | sed 's/^ //; s/\.//g'
          ;;
        datetime)
          date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null | sed 's/  / /g; s/^ //; s/\.//g' | tr '[:upper:]' '[:lower:]' || \
          date -d "@$epoch" +"%b %-d, %l:%M%P" 2>/dev/null | sed 's/  / /g; s/^ //; s/\.//g'
          ;;
        *)
          date -j -r "$epoch" +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]' || \
          date -d "@$epoch" +"%b %-d" 2>/dev/null
          ;;
      esac
    }

    # ── Extract JSON data ───────────────────────────────────
    model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')

    size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
    [ "$size" -eq 0 ] 2>/dev/null && size=200000

    input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
    cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
    cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
    current=$(( input_tokens + cache_create + cache_read ))

    used_tokens=$(format_tokens $current)
    total_tokens=$(format_tokens $size)

    if [ "$size" -gt 0 ]; then
      pct_used=$(( current * 100 / size ))
    else
      pct_used=0
    fi

    thinking_on=false
    settings_path="$HOME/.claude/settings.json"
    if [ -f "$settings_path" ]; then
      thinking_val=$(jq -r '.alwaysThinkingEnabled // false' "$settings_path" 2>/dev/null)
      [ "$thinking_val" = "true" ] && thinking_on=true
    fi

    # ── LINE 1: Model │ Context % │ Directory (branch) │ Session │ Thinking ──
    pct_color=$(color_for_pct "$pct_used")
    cwd=$(echo "$input" | jq -r '.cwd // ""')
    [ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd=$(pwd)
    dirname=$(basename "$cwd")

    git_branch=""
    git_dirty=""
    if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
      if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
        git_dirty="*"
      fi
    fi

    session_duration=""
    session_start=$(echo "$input" | jq -r '.session.start_time // empty')
    if [ -n "$session_start" ] && [ "$session_start" != "null" ]; then
      start_epoch=$(iso_to_epoch "$session_start")
      if [ -n "$start_epoch" ]; then
        now_epoch=$(date +%s)
        elapsed=$(( now_epoch - start_epoch ))
        if [ "$elapsed" -ge 3600 ]; then
          session_duration="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
        elif [ "$elapsed" -ge 60 ]; then
          session_duration="$(( elapsed / 60 ))m"
        else
          session_duration="''${elapsed}s"
        fi
      fi
    fi

    line1="''${blue}''${model_name}''${reset}"
    line1+="''${sep}"
    line1+="✍️ ''${pct_color}''${pct_used}%''${reset}"
    line1+="''${sep}"
    line1+="''${cyan}''${dirname}''${reset}"
    if [ -n "$git_branch" ]; then
      line1+=" ''${green}(''${git_branch}''${red}''${git_dirty}''${green})''${reset}"
    fi
    if [ -n "$session_duration" ]; then
      line1+="''${sep}"
      line1+="''${dim}⏱ ''${reset}''${white}''${session_duration}''${reset}"
    fi
    line1+="''${sep}"
    if $thinking_on; then
      line1+="''${magenta}◐ thinking''${reset}"
    else
      line1+="''${dim}◑ thinking''${reset}"
    fi

    # ── OAuth token resolution ──────────────────────────────
    get_oauth_token() {
      local token=""

      if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        echo "$CLAUDE_CODE_OAUTH_TOKEN"
        return 0
      fi

      if command -v security >/dev/null 2>&1; then
        local blob
        blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
        if [ -n "$blob" ]; then
          token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
          if [ -n "$token" ] && [ "$token" != "null" ]; then
            echo "$token"
            return 0
          fi
        fi
      fi

      local creds_file="''${HOME}/.claude/.credentials.json"
      if [ -f "$creds_file" ]; then
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
          echo "$token"
          return 0
        fi
      fi

      if command -v secret-tool >/dev/null 2>&1; then
        local blob
        blob=$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
        if [ -n "$blob" ]; then
          token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
          if [ -n "$token" ] && [ "$token" != "null" ]; then
            echo "$token"
            return 0
          fi
        fi
      fi

      echo ""
    }

    # ── Fetch usage data (cached) ──────────────────────────
    cache_file="/tmp/claude/statusline-usage-cache.json"
    cache_max_age=60
    mkdir -p /tmp/claude

    needs_refresh=true
    usage_data=""

    if [ -f "$cache_file" ]; then
      cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
      now=$(date +%s)
      cache_age=$(( now - cache_mtime ))
      if [ "$cache_age" -lt "$cache_max_age" ]; then
        needs_refresh=false
        usage_data=$(cat "$cache_file" 2>/dev/null)
      fi
    fi

    if $needs_refresh; then
      token=$(get_oauth_token)
      if [ -n "$token" ] && [ "$token" != "null" ]; then
        response=$(curl -s --max-time 5 \
          -H "Accept: application/json" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $token" \
          -H "anthropic-beta: oauth-2025-04-20" \
          -H "User-Agent: claude-code/2.1.34" \
          "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if [ -n "$response" ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
          usage_data="$response"
          echo "$response" > "$cache_file"
        fi
      fi
      if [ -z "$usage_data" ] && [ -f "$cache_file" ]; then
        usage_data=$(cat "$cache_file" 2>/dev/null)
      fi
    fi

    # ── Rate limit lines ────────────────────────────────────
    rate_lines=""

    if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
      bar_width=10

      five_hour_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
      five_hour_reset_iso=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')
      five_hour_reset=$(format_reset_time "$five_hour_reset_iso" "time")
      five_hour_bar=$(build_bar "$five_hour_pct" "$bar_width")
      five_hour_pct_color=$(color_for_pct "$five_hour_pct")
      five_hour_pct_fmt=$(printf "%3d" "$five_hour_pct")

      rate_lines+="''${white}current''${reset} ''${five_hour_bar} ''${five_hour_pct_color}''${five_hour_pct_fmt}%''${reset} ''${dim}⟳''${reset} ''${white}''${five_hour_reset}''${reset}"

      seven_day_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')
      seven_day_reset_iso=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty')
      seven_day_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")
      seven_day_bar=$(build_bar "$seven_day_pct" "$bar_width")
      seven_day_pct_color=$(color_for_pct "$seven_day_pct")
      seven_day_pct_fmt=$(printf "%3d" "$seven_day_pct")

      rate_lines+="\n''${white}weekly''${reset}  ''${seven_day_bar} ''${seven_day_pct_color}''${seven_day_pct_fmt}%''${reset} ''${dim}⟳''${reset} ''${white}''${seven_day_reset}''${reset}"

      extra_enabled=$(echo "$usage_data" | jq -r '.extra_usage.is_enabled // false')
      if [ "$extra_enabled" = "true" ]; then
        extra_pct=$(echo "$usage_data" | jq -r '.extra_usage.utilization // 0' | awk '{printf "%.0f", $1}')
        extra_used=$(echo "$usage_data" | jq -r '.extra_usage.used_credits // 0' | awk '{printf "%.2f", $1/100}')
        extra_limit=$(echo "$usage_data" | jq -r '.extra_usage.monthly_limit // 0' | awk '{printf "%.2f", $1/100}')
        extra_bar=$(build_bar "$extra_pct" "$bar_width")
        extra_pct_color=$(color_for_pct "$extra_pct")

        extra_reset=$(date -v+1m -v1d +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        if [ -z "$extra_reset" ]; then
          extra_reset=$(date -d "$(date +%Y-%m-01) +1 month" +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        fi

        extra_col="''${white}extra''${reset}   ''${extra_bar} ''${extra_pct_color}\$''${extra_used}''${dim}/''${reset}''${white}\$''${extra_limit}''${reset}"
        extra_reset_line="''${dim}resets ''${reset}''${white}''${extra_reset}''${reset}"
        rate_lines+="\n''${extra_col}"
        rate_lines+="\n''${extra_reset_line}"
      fi
    fi

    # ── Output ──────────────────────────────────────────────
    printf "%b" "$line1"
    [ -n "$rate_lines" ] && printf "\n\n%b" "$rate_lines"

    exit 0
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
