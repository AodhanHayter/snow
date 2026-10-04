{ inputs, ... }:
final: prev: {
  grok = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.grok;
}
