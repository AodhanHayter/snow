{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.codex;
in
{
  options.modernage.cli-apps.codex = {
    enable = mkBoolOpt false "Whether or not to install and configure codex.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ codex ];
  };
}
