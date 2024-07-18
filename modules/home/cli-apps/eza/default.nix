{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.eza;
in
{
  options.modernage.cli-apps.eza = {
    enable = mkBoolOpt false "Whether or not to install and configure eza.";
  };

  config = mkIf cfg.enable {
    programs.eza = {
      enable = true;
      extraOptions = [ "--icons" ];
    };
  };
}
