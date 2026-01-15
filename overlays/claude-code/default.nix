{ inputs, ... }:
final: prev: {
  claude-code = inputs.claude-code-nix.packages.${prev.stdenv.hostPlatform.system}.default;
}
