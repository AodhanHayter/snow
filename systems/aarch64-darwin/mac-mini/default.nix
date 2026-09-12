{
  pkgs,
  config,
  lib,
  channel,
  ...
}:
with lib;
with lib.modernage;
{
  modernage = {
    user = {
      name = "aodhanhayter";
    };

    prototype = {
      workstation = enabled;
    };

    services = {
      tailscale = enabled;
    };
  };

  # Always reachable over ssh/tailscale: never sleep, wake on LAN, recover from power loss
  power = {
    sleep = {
      computer = "never";
      display = 20;
      harddisk = "never";
    };
    restartAfterPowerFailure = true;
    restartAfterFreeze = true;
  };

  # Used for backwards compatibility, please read the changelog before changing
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
