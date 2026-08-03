{ inputs, ... }:
final: prev: {
  grok = inputs.grok-build-nix.packages.${prev.stdenv.hostPlatform.system}.grok;
}
