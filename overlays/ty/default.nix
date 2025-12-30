{ channels, ... }:
final: prev: {
  inherit (channels.unstable) ty;
}
