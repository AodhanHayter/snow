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
        "Bash(nix flake check)"
        "Bash(nix build*)"
        "Bash(nix fmt)"
        "Bash(nix develop)"
        "Bash(deploy*)"
      ];
      deny = [];
    };
    env = {
      CLAUDE_CODE_ENABLE_TELEMETRY = "0";
      CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
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

    home.file.".claude/settings.json" = {
      text = builtins.toJSON settings;
    };
  };
}
