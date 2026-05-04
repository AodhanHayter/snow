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
      hash = "sha256-t80gNEapVvEtO0OKaIQL3uckGB0byUdi3rii4cLRPMU=";
    };
    "x86_64-linux" = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-tOqhu1JYirzlKkv/otH5hNkOE7y3XxKkVlYgXJ9PmEA=";
    };
  };

  platform = platforms.${system} or (throw "fff-mcp: unsupported system ${system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "fff-mcp";
  version = "0.7.0";

  src = fetchurl {
    url = "https://github.com/dmtrKovalenko/fff/releases/download/v${version}/fff-mcp-${platform.target}";
    hash = platform.hash;
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 $src $out/bin/fff-mcp
  '';

  meta = {
    description = "File search toolkit MCP server optimized for AI agents";
    homepage = "https://github.com/dmtrKovalenko/fff";
    license = lib.licenses.mit;
    mainProgram = "fff-mcp";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
