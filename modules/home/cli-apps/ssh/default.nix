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
      # HM 26.05: `matchBlocks` -> `settings`, per-block options use upstream
      # OpenSSH directive names directly (no `extraOptions` wrapper).
      settings = {
        # Tailnet hosts (Tailscale IPs)
        "ultimo" = {
          HostName = "100.106.9.108";
          User = "aodhan";
        };
        "mac-mini" = {
          HostName = "100.72.144.108";
          User = "aodhanhayter";
        };
        "mac-mini.local" = {
          HostName = "mac-mini.local";
          User = "aodhanhayter";
        };
        "maximo" = {
          HostName = "100.73.146.77";
          User = "aodhan";
        };

        # LAN lab nodes (mDNS)
        "apollo" = {
          HostName = "apollo.local";
          User = "aodhan";
        };
        "atlas" = {
          HostName = "atlas.local";
          User = "aodhan";
        };
        "hermes" = {
          HostName = "hermes.local";
          User = "aodhan";
        };

        # Fallback defaults — IgnoreUnknown suppresses UseKeychain errors on non-macOS
        "*" = {
          IgnoreUnknown = "UseKeychain";
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
          IdentityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
