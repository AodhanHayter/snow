{ inputs, ... }:
final: prev: {
  codex-cli = inputs.codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
}
