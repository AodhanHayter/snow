{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.ripgrep;
in
{
  options.modernage.cli-apps.ripgrep = {
    enable = mkBoolOpt false "Whether or not to install and configure ripgrep.";
  };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
    };
  };
}
