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

  settings = {
    permissions = {
      allow = [
        # Nix commands
        "Bash(nix flake check)"
        "Bash(nix build*)"
        "Bash(nix fmt)"
        "Bash(nix develop)"
        "Bash(deploy*)"

        # Read-only file operations
        "Bash(ls*)"
        "Bash(cat*)"
        "Bash(head*)"
        "Bash(tail*)"
        "Bash(grep*)"
        "Bash(rg*)"
        "Bash(fd*)"
        "Bash(find*)"
        "Bash(which*)"
        "Bash(pwd)"
        "Bash(whoami)"
        "Bash(uname*)"

        # Git read operations
        "Bash(git status)"
        "Bash(git log*)"
        "Bash(git diff*)"
        "Bash(git branch*)"
        "Bash(git remote*)"
        "Bash(git show*)"

        # Package manager read operations
        "Bash(npm list*)"
        "Bash(yarn list*)"
        "Bash(cargo tree)"
        "Bash(pip list)"
        "Bash(gem list)"

        # System information
        "Bash(date)"
        "Bash(echo*)"
        "Bash(env)"
        "Bash(printenv)"
        "Bash(locale*)"

        # File analysis
        "Bash(file*)"
        "Bash(wc*)"
        "Bash(du*)"
        "Bash(tree*)"
        "Bash(stat*)"

        # Text processing
        "Bash(sed*)"
        "Bash(awk*)"
        "Bash(sort*)"
        "Bash(uniq*)"
        "Bash(cut*)"
        "Bash(tr*)"

        # JSON/YAML tools
        "Bash(jq*)"
        "Bash(yq*)"

        # devenv and direnv integration
        "Bash(devenv*)"
        "Bash(direnv*)"
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
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ claude-code ];

    # This makes Claude Code compatible with direnv and devenv
    # Claude Code sets the CLAUDECODE=1 environment variable.
    # This conditional setup ensures direnv hooks are only installed for Claude Code sessions.
    programs.zsh.envExtra = ''
      if [[ -n "$CLAUDECODE" ]]; then
        eval "$(devenv direnvrc)"
      fi
    '';

    home.file.".claude/settings.json" = {
      text = builtins.toJSON settings;
    };
  };
}
