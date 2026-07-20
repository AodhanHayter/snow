{ ... }:
final: prev: {
  beads-rust = final.callPackage ../../packages/beads-rust/default.nix { };
}
