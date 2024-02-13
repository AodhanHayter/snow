{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.bat;
in
{
  options.modernage.cli-apps.bat = {
    enable = mkBoolOpt false "Whether or not to install and configure bat.";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
    };
  };
}
