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
      hash = "sha256-Kg1ZTx7FSxqUU8N2xKnGJ371SMhp9gusRsvSKSglHoM=";
    };
    "x86_64-linux" = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-FwSlM/DkDtErrDwTJzrB4JXiDD7r7VDMZxH3Bz6qUFw=";
    };
  };

  platform = platforms.${system} or (throw "dcg: unsupported system ${system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "dcg";
  version = "0.4.0";

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
