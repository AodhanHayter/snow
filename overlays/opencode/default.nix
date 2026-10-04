{ inputs, ... }:
final: prev: {
  opencode = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.opencode;
}
