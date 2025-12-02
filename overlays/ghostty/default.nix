{ inputs, ... }:
final: prev: {
  ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default;
}
