{ inputs, ... }:
final: prev: {
  claude-code = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.claude-code;
}
