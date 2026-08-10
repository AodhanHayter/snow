{ inputs, ... }:
final: prev: {
  # upstream ships the code-mode-host sidecar itself since 0.146.x
  # (https://github.com/sadjow/codex-cli-nix/issues/121)
  codex-cli = inputs.codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
}
