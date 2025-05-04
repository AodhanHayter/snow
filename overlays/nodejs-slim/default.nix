{ channels, ... }:
final: prev: {
  # nodejs-slim build is broken at the moment.
  nodejs-slim = channels.nixpkgs.nodejs-slim_22;
}
