{ inputs, ... }:
final: prev: {
  expert = inputs.expert.packages.${prev.stdenv.hostPlatform.system}.default;
}