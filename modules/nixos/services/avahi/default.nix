{options, config, lib, pkgs, ...}:
with lib;
with lib.modernage; let
  cfg = config.modernage.services.avahi;
in {
  options.modernage.services.avahi = with types; {
    enable = mkBoolOpt false "Whether or not to enable avahi.";
  };

  config = mkIf cfg.enable {
    services.avahi.enable = true;
  };
}
