{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.home-manager;
in
{
  options.modernage.cli-apps.home-manager = {
    enable = mkBoolOpt false "Whether or not to enable home-manager.";
  };

  config = mkIf cfg.enable {
    programs.home-manager = enabled;
  };
}

