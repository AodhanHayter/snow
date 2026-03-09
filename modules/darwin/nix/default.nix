{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.nix;
in
{
  options.modernage.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      deploy-rs
      nixfmt-rfc-style
      nix-index
      nix-prefetch-git
    ];

    environment.etc."nix/nix.custom.conf".text = ''
      eval-cores = 2
      http-connections = 50
      warn-dirty = false
      log-lines = 50
      allow-import-from-derivation = true
      trusted-users = root ${config.modernage.user.name}
      allowed-users = root ${config.modernage.user.name}
      extra-nix-path = nixpkgs=flake:nixpkgs
      extra-substituters = https://nixpkgs-python.cachix.org https://devenv.cachix.org
      extra-trusted-public-keys = nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU= devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
    '';

    # nix-darwin module disabled; determinate-nix manages the nix installation
    nix = {
      enable = false;
      generateNixPathFromInputs = true;
      linkInputs = true;
    };
  };
}
