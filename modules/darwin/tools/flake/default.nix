{ lib
, config
, pkgs
, ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.flake;
in
{
  options.modernage.tools.flake = {
    enable = mkEnableOption "Flake";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      snowfallorg.flake
    ];
  };
}
