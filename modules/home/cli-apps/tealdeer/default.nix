{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.tealdeer;
in
{
  options.modernage.cli-apps.tealdeer = {
    enable = mkBoolOpt false "Whether or not to install and configure tealdeer.";
  };

  config = mkIf cfg.enable {
    programs.tealdeer = {
      enable = true;
    };
  };
}
