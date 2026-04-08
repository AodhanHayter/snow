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

    tools.agent-dev-vm = {
      enable = true;
      vms.test = {
        mem = 4096;
        vcpu = 2;
        projects = {
          snow = "/Users/aodhan/development/snow";
        };
      };
    };
  };

  # Used for backwards compatibility, please read the changelog before changing
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
