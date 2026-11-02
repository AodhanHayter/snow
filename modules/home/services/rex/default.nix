{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.services.rex;
in
{
  options.modernage.services.rex = {
    enable = mkBoolOpt false "Whether to run a personal Rex server over Tailscale.";
  };

  config = mkIf cfg.enable {
    services.rex = {
      enable = true;
      tailscale.enable = true;
    };
  };
}
