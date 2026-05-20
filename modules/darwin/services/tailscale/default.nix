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
    splitDns = mkOpt (attrsOf (listOf str)) { } ''
      Per-domain DNS resolver overrides written under /etc/resolver/.
      macOS routes any query matching <domain> (suffix match) to the listed
      nameservers. Use 100.100.100.100 for Tailscale's resolver to honor
      tailnet-side split-DNS rules (the Tailscale CLI on macOS does not
      auto-register these — only MagicDNS suffix gets a resolver file).
      Example: { "postgres.database.azure.com" = [ "100.100.100.100" ]; }
    '';
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      tailscale
    ];

    environment.etc = mapAttrs' (
      domain: nameservers:
      nameValuePair "resolver/${domain}" {
        text = concatMapStrings (ns: "nameserver ${ns}\n") nameservers;
      }
    ) cfg.splitDns;
  };
}
