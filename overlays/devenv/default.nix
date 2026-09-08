{ channels, ... }:
final: prev: {
  # devenv 2.3 not yet in nixpkgs-unstable; tracking NixOS/nixpkgs#560896
  inherit (channels.unstable) devenv;
}
