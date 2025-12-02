{ inputs, ... }:
final: prev: {
  opencode = inputs.opencode.packages.${prev.stdenv.hostPlatform.system}.default;
}
