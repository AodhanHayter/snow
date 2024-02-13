{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.obs-studio;
in
{
  options.modernage.apps.obs-studio = {
    enable = mkBoolOpt false "Whether or not to install and configure obs-studio.";
  };

  config = mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
    };
  };
}
