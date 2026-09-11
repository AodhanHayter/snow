{ inputs, ... }:
final: prev: {
  # upstream flake tracks releases ahead of nixpkgs; cached in devenv.cachix.org
  devenv = inputs.devenv.packages.${prev.stdenv.hostPlatform.system}.devenv;
}
