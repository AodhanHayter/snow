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
      name = "aodhan";
    };

    prototype = {
      workstation = enabled;
    };

    services = {
      tailscale = enabled;
    };
  };

  # Used for backwards compatibility, please read the changelog before changing
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
