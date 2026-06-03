{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
with lib;
with lib.modernage;
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  # WSL owns boot + networking; only enable headless-safe modules.
  wsl = {
    enable = true;
    defaultUser = "aodhan";
    startMenuLaunchers = true;
  };

  modernage = {
    nix = enabled;

    tools = {
      git = enabled;
      nodejs = enabled;
    };

    system = {
      locale = enabled;
      time = enabled;
    };

    security = {
      doas = enabled;
    };

    services = {
      # Reachable at the Windows host IP when WSL2 mirrored networking is on.
      # Set in Windows %UserProfile%\.wslconfig, then `wsl --shutdown`:
      #   [wsl2]
      #   networking=mirrored
      openssh = enabled;
    };

    cli-apps = {
      neovim = enabled;
      tmux = enabled;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}
