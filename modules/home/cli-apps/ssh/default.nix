{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.ssh;
in
{
  options.modernage.cli-apps.ssh = {
    enable = mkBoolOpt false "Whether to enable SSH config management.";
  };

  config = mkIf cfg.enable {
    services.ssh-agent.enable = true;

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        # Tailnet hosts (Tailscale IPs)
        "ultimo" = {
          hostname = "100.106.9.108";
          user = "aodhan";
        };
        "mac-mini" = {
          hostname = "100.72.144.108";
          user = "aodhanhayter";
        };
        "maximo" = {
          hostname = "100.73.146.77";
          user = "aodhan";
        };

        # LAN lab nodes (mDNS)
        "apollo" = {
          hostname = "apollo.local";
          user = "aodhan";
        };
        "atlas" = {
          hostname = "atlas.local";
          user = "aodhan";
        };
        "hermes" = {
          hostname = "hermes.local";
          user = "aodhan";
        };

        # Fallback defaults — IgnoreUnknown suppresses UseKeychain errors on non-macOS
        "*" = {
          extraOptions = {
            IgnoreUnknown = "UseKeychain";
            AddKeysToAgent = "yes";
            UseKeychain = "yes";
          };
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
