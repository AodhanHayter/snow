{ inputs, ... }:
final: prev: {
  expert = inputs.expert.packages.${prev.system}.default;
}