{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.opencode;
in
{
  options.modernage.cli-apps.opencode = {
    enable = mkBoolOpt false "Whether or not to install and configure opencode.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ opencode ];

    home.file.".config/opencode/config.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      theme = "nord";
      model = "anthropic/claude-sonnet-4-20250514";
      autoshare = false;
      autoupdate = false;
    };
  };
}
