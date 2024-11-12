{ pkgs
, config
, lib
, channel
, modulesPath
, ...
}:
with lib;
with lib.modernage; {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./hardware.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  modernage = {
      nix = enabled;

      tools = {
        git = enabled;
      };

      hardware = {
        networking = enabled;
      };

      system = {
        fonts = enabled;
        locale = enabled;
        time = enabled;
        xkb = enabled;
      };

      cli-apps = {
        neovim = enabled;
        tmux = enabled;
      };

      services = {
        openssh = enabled;
      };

  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
