{ channels, ... }:
final: prev: {
  # nodejs-slim build is broken at the moment.
  nodejs_20 = channels.nixpkgs.nodejs_22;
}
