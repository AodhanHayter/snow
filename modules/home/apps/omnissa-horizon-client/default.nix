{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.omnissa-horizon-client;
in
{
  options.modernage.apps.omnissa-horizon-client = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure Omnissa Horizon Virtual Desktop.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.omnissa-horizon-client ];
  };
}
