{ inputs, ... }:
final: prev: {
  beads = prev.buildGoModule {
    pname = "beads";
    version = "0.29.0";
    src = inputs.beads;
    subPackages = [ "cmd/bd" ];
    vendorHash = "sha256-KRR6dXzsSw8OmEHGBEVDBOoIgfoZ2p0541T9ayjGHlI=";
    doCheck = false;
    nativeBuildInputs = [ prev.git ];
    meta = {
      description = "An issue tracker designed for AI-supervised coding workflows";
      license = prev.lib.licenses.mit;
    };
  };
}
