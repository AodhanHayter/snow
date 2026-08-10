{ channels, ... }:
final: prev: {
  inherit (channels.unstable.beamPackages) expert;
}
