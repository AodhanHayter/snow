{ channels, ... }:
final: prev: {
  # rtk 0.43.0 source sets `-D warnings`; its test build trips dead_code lints.
  rtk = channels.unstable.rtk.overrideAttrs (_: {
    doCheck = false;
  });
}
