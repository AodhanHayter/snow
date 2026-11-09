{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  inputs,
  ...
}:
let
  # Upstream stable-channel manifest, pinned via flake.lock.
  release = (lib.importJSON inputs.browse-release).release;
  system = stdenvNoCC.hostPlatform.system;
  targets = {
    aarch64-darwin = "macos-arm64";
    x86_64-linux = "linux-x64";
  };
  target = release.targets.${targets.${system} or (throw "browse: unsupported system ${system}")};
  isLinux = stdenvNoCC.hostPlatform.isLinux;
in
stdenvNoCC.mkDerivation {
  pname = "browse";
  inherit (release) version;

  src = fetchurl {
    url = "https://anoma.ly${target.url}";
    sha256 = target.sha256;
  };

  sourceRoot = "package";

  nativeBuildInputs = [
    makeWrapper
  ]
  # bun --compile binary: patchelf/autoPatchelf break its EOF payload; wrapBuddy patches in place.
  ++ lib.optional isLinux inputs.llm-agents.packages.${system}.wrapBuddy;

  dontBuild = true;
  dontStrip = true;

  # Self-update would overwrite ~/.local/bin; nix flake update handles bumps.
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/browse $out/libexec/browse
    makeWrapper $out/libexec/browse $out/bin/browse \
      --set-default OPENCODE_BROWSER_AUTO_UPDATE off \
      --set-default OPENCODE_BROWSER_UPDATE_CHECK 0
    runHook postInstall
  '';

  meta = {
    description = "MCP server + Chromium extension relay letting agents drive your real browser";
    homepage = "https://opencode.ai/product/browse";
    license = lib.licenses.mit;
    mainProgram = "browse";
    platforms = builtins.attrNames targets;
  };
}
