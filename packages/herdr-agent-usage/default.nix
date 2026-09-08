{
  lib,
  buildGoModule,
  inputs,
}:
buildGoModule rec {
  pname = "herdr-agent-usage";
  version = "0.5.13";

  src = inputs.herdr-agent-usage;
  vendorHash = "sha256-PG1aBfMkmrt+Vb0P+4my2nQ9sqshoqGWhQM9BzDvj48=";

  doCheck = false;

  buildPhase = ''
    runHook preBuild
    mkdir -p bin
    go build -o bin/usagebar ./cmd/usagebar
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R bin herdr-plugin.toml "$out/"
    chmod +x "$out"/bin/*.sh "$out"/bin/usagebar
    runHook postInstall
  '';

  meta = {
    description = "Herdr plugin for agent context and provider usage meters";
    homepage = "https://github.com/senna-lang/herdr-agent-usage";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
