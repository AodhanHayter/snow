{pkgs, lib, ...}:
with lib;
with lib.modernage; {

  networking.wireless.enable = mkForce false;

  modernage = {
    nix = enabled;

    cli-apps = {
      neovim = enabled;
      tmux = enabled;
    };

    tools = {
      git = enabled;
    };

    hardware = {
      networking = enabled;
    };

    services = {
      openssh = enabled;
    };

    system = {
      boot = enabled;
      fonts = enabled;
      locale = enabled;
      time = enabled;
      xkb = enabled;
    };
  };
}
