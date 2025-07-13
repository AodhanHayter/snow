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
  cfg = config.modernage.services.tailscale;
in
{
  options.modernage.services.tailscale = with types; {
    enable = mkBoolOpt false "Whether or not to enable Tailscale VPN service.";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      tailscale
    ];
  };
}
