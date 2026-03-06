{ inputs, ... }:
final: prev: {
  devenv = inputs.devenv.packages.${prev.stdenv.hostPlatform.system}.devenv;
}
