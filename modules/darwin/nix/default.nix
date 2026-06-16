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
      nixfmt
      nix-index
      nix-prefetch-git
    ];

    environment.etc."nix/nix.custom.conf".text = ''
      eval-cores = 0
      http-connections = 50
      warn-dirty = false
      log-lines = 50
      allow-import-from-derivation = true
      trusted-users = root ${config.modernage.user.name}
      allowed-users = root ${config.modernage.user.name}
      extra-nix-path = nixpkgs=flake:nixpkgs
      extra-substituters = https://nixpkgs-python.cachix.org https://herdr-nix.cachix.org https://claude-code.cachix.org https://nix-community.cachix.org
      extra-trusted-public-keys = nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU= devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= herdr-nix.cachix.org-1:+AT7TY8E6j/Pe9lB8Vjmp15Y4RPb8YtOnOwr/fboDS8= claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
      extra-experimental-features = external-builders wasm-builtin
      external-builders = [{"systems":["aarch64-linux","x86_64-linux"],"program":"/usr/local/bin/determinate-nixd","args":["builder"]}]
    '';

    # nix-darwin module disabled; determinate-nix manages the nix installation
    nix = {
      enable = false;
      generateNixPathFromInputs = true;
      linkInputs = true;
    };
  };
}
