{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.prototype.workstation;
in
{
  options.modernage.prototype.workstation = with types; {
    enable = mkBoolOpt false "Whether or not to enable the workstation prototype.";
  };

  config = mkIf cfg.enable {
    modernage = {
      desktop = {
        fonts = enabled;
      };

      suites = {
        common = enabled;
        desktop = enabled;
      };
    };
  };
}
