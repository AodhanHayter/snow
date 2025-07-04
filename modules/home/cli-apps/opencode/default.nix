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
  user = config.modernage.user;
  home-directory = if pkgs.stdenv.isDarwin then "/Users/${user.name}" else "/home/${user.name}";
  configPath = "${home-directory}/.config/opencode/config.json";
in
{
  options.modernage.cli-apps.opencode = {
    enable = mkBoolOpt false "Whether or not to install and configure opencode.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ opencode ];

    sops.templates."opencode_config.json" = {
      mode = "0600";
      path = configPath;
      content = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        theme = "nord";
        model = "anthropic/claude-sonnet-4-20250514";
        autoshare = false;
        autoupdate = false;
        mcp = mcp.asOpenCodeFormat { inherit config pkgs; };
      };
    };
  };
}
