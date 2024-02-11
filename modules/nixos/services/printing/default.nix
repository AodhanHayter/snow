{options, config, lib, pkgs, ...}:
with lib;
with lib.modernage; let
  cfg = config.modernage.services.printing;
in {
  options.modernage.services.printing = with types; {
    enable = mkBoolOpt false "Whether or not to enable printing.";
  };

  config = mkIf cfg.enable {
    services.printing.enable = true;
  };
}
