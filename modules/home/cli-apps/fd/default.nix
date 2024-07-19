{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.fd;
in
{
  options.modernage.cli-apps.fd = {
    enable = mkBoolOpt false "Whether or not to install and configure fd.";
  };

  config = mkIf cfg.enable {
    programs.fd = {
      enable = true;
    };
  };
}
