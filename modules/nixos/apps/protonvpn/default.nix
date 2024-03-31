{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.protonvpn;
in
{
  options.modernage.apps.protonvpn = with types; {
    enable = mkBoolOpt false "Whether or not to install protonvpn GUI.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.protonvpn-gui ];
  };
}
