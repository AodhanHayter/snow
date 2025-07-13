{ inputs, ... }:
final: prev: {
  hyprddm = inputs.hyprddm.packages.${prev.system}.default;
}
