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
    useRoutingFeatures = mkOpt (enum [
      "none"
      "client"
      "server"
      "both"
    ]) "none" "Which routing features to enable.";
    openFirewall = mkBoolOpt false "Whether to open the firewall for Tailscale.";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = cfg.useRoutingFeatures;
      openFirewall = cfg.openFirewall;
    };
  };
}
