{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.11.2";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/bv_${version}_darwin_arm64.tar.gz";
      hash = "sha256-grsR4PzdoVW6YYRgxv8OYF+kqXnHXF07dtqEmhdVKFg=";
    };
    x86_64-darwin = {
      url = "https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/bv_${version}_darwin_amd64.tar.gz";
      hash = "sha256-Oxts0DV0Ig0OTJpGE/xTptvSdW+aPHy9kLNvRR96b/U=";
    };
    x86_64-linux = {
      url = "https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/bv_${version}_linux_amd64.tar.gz";
      hash = "sha256-ytPk8qPbwlojrG3aYWzNAdFYgT/tKeGAQkx1R9KCZRY=";
    };
    aarch64-linux = {
      url = "https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/bv_${version}_linux_arm64.tar.gz";
      hash = "sha256-E9wM+UG8Yj5FbZUBp18QlOFi0q02zHmlXbEu0sHXh/I=";
    };
  };

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "beads-viewer";
  inherit version src;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 bv $out/bin/bv
    runHook postInstall
  '';

  meta = {
    description = "TUI for Beads issue tracker";
    homepage = "https://github.com/Dicklesworthstone/beads_viewer";
    license = lib.licenses.mit;
    mainProgram = "bv";
    platforms = builtins.attrNames sources;
  };
}
