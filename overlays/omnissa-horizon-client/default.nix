{ channels, ... }:
final: prev: {
  inherit (channels.unstable) omnissa-horizon-client;
}
