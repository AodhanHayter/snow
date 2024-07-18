{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.mos;
in
{
  options.modernage.apps.mos = with types; {
    enable = mkBoolOpt false "Whether or not to enable Mos.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.mos ];
  };
}
