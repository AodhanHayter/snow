{ inputs, ... }:
final: prev: {
  beads = inputs.beads.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    vendorHash = "sha256-ovG0EWQFtifHF5leEQTFvTjGvc+yiAjpAaqaV0OklgE=";
  });
}
