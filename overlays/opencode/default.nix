{inputs, ...}:
final: prev: {
  opencode = inputs.opencode.packages.${prev.system}.default;
}
