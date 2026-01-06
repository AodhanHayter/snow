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

      # Server capabilities
      openssh = enabled;
      avahi = enabled;
    };
  };

  # Always-on server mode - disable auto-suspend but allow manual shutdown
  powerManagement.enable = false;
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandlePowerKey = "poweroff";  # Power button = clean shutdown
    IdleAction = "ignore";
  };

  # Sunshine remote desktop (NVIDIA hardware encoding)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for KMS capture
    openFirewall = true;
  };
  modernage.user.extraGroups = [ "input" ];  # Required for Sunshine input control
  # udev rule to allow input group access to uinput
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';
  # Sunshine needs avahi for discovery
  networking.firewall.allowedUDPPorts = [ 5353 ];

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
