{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.entr;
in
{
  options.modernage.cli-apps.entr = {
    enable = mkBoolOpt false "Whether or not to install and configure entr.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ entr ];
  };
}
