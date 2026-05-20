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
      tailscale = enabled // {
        splitDns."postgres.database.azure.com" = [ "100.100.100.100" ];
      };
    };
  };

  # Used for backwards compatibility, please read the changelog before changing
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
