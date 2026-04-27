{ channels, ... }:
final: prev: {
  direnv = channels.unstable.direnv.overrideAttrs (_: {
    doCheck = false;
  });
}
