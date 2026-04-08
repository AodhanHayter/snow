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

    tools = {
      sops = enabled;
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

      # ZEC DCA bot
      crypt-dca = disabled;

      # Nix binary cache
      harmonia = enabled;
    };

    hardware = {
      rgb = enabled;
    };

    tools.agent-dev-vm = {
      enable = true;
      vms.test = {
        mem = 8192;
        vcpu = 4;
        sshPort = 2322;
        projects = {
          snow = "/home/aodhan/development/snow";
          testproject = "/home/aodhan/development/test-devenv-project";
        };
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIO1hPvqjkAi/2mfCNOqhOYYvTcCO5eeqUxOEbkZxLh5 avm-test"
        ];
      };
    };
  };

  # Always-on server mode
  powerManagement.enable = false;
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandlePowerKey = "poweroff";
    IdleAction = "ignore";
  };

  # Prevent any sleep/suspend/hibernate states
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Auto-reboot on kernel panic (10s delay) and hung tasks
  boot.kernelParams = [ "panic=10" ];
  boot.kernel.sysctl = {
    "kernel.panic_on_oops" = 1;
    "kernel.hung_task_panic" = 1;
  };

  # Systemd watchdog - reboot if system becomes unresponsive
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10m";
  };

  # SSD health maintenance
  services.fstrim.enable = true;

  # Sunshine remote desktop (NVIDIA hardware encoding)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for KMS capture
    openFirewall = true;
  };
  modernage.user.extraGroups = [ "uinput" ];  # Required for Sunshine input control
  # Auto-login for remote desktop access via Sunshine
  services.displayManager.autoLogin = {
    enable = true;
    user = "aodhan";
  };
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
