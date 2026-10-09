{ channels, ... }:
final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  # Stable still compiles bundled Catch tests that fail on Darwin.
  inherit (channels.unstable) thrift;
}
