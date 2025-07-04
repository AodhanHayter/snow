{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.ast-grep;
in
{
  options.modernage.cli-apps.ast-grep = {
    enable = mkBoolOpt false "Whether or not to install and configure ast-grep.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ ast-grep ];
  };
}
