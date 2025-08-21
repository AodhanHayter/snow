{pkgs, lib, inputs, ...}:
let
  inherit (inputs) nixos-hardware;
in
with lib;
with lib.modernage; {

  imports = with nixos-hardware.nixosModules; [
    apple-mbp-11-5
  ];

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
