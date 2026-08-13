{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:
let
  system = stdenvNoCC.hostPlatform.system;
  platforms = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      hash = "sha256-cqv8jalejJAhuG1qs9RKgXgSyIEdmCqF3VjcVo31OAA=";
    };
    "x86_64-linux" = {
      # 0.10+ ships musl static-pie only for x86_64 linux.
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-Kg3PpxFsr53hGnpO46NRuvtSHgF5RBbzxryLNEc1nMs=";
    };
  };

  platform = platforms.${system} or (throw "dcg: unsupported system ${system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "dcg";
  version = "0.10.0";

  src = fetchurl {
    url = "https://github.com/Dicklesworthstone/destructive_command_guard/releases/download/v${version}/dcg-${platform.target}.tar.xz";
    hash = platform.hash;
  };

  sourceRoot = ".";
  unpackCmd = "tar xf $curSrc";

  installPhase = ''
    install -Dm755 dcg $out/bin/dcg
  '';

  meta = {
    description = "Hook for AI coding agents that blocks destructive commands";
    homepage = "https://github.com/Dicklesworthstone/destructive_command_guard";
    license = lib.licenses.mit;
    mainProgram = "dcg";
  };
}
