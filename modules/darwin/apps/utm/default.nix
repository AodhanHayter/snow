{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.utm;
in
{
  options.modernage.apps.utm = with types; {
    enable = mkBoolOpt false "Whether or not to enable UTM.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.utm ];
  };
}
