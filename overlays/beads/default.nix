{ inputs, ... }:
final: prev: {
  beads = inputs.beads.packages.${prev.stdenv.hostPlatform.system}.default;
}
