{ inputs, ... }:
final: prev: {
  codex-cli = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.codex;
}
