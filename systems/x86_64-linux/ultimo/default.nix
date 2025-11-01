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
  imports = [ ./hardware.nix ];

  modernage = {
    prototype = {
      workstation = enabled;
    };

    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
      };

      # Enable keyd for macOS-style keyboard shortcuts
      keyd = enabled;
    };
  };

  virtualisation.vmVariant = {
    users.users.testuser = {
      isNormalUser = true;
      password = "test";
      extraGroups = [ "wheel" ];
    };

    users.users.root.password = "root";
    security.sudo.wheelNeedsPassword = false;

    virtualisation = {
      memorySize = 2048;
      cores = 2;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}
