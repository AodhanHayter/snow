{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  ...
}:
buildNpmPackage rec {
  pname = "browse";
  version = "0.0.16";

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode/browse/-/browse-${version}.tgz";
    hash = "sha256-Yt78xDraYiBpsOVKjBsn7L5YZwHSTd/AuRUYAb7RKrg=";
  };

  nodejs = nodejs_22;

  # Tarball ships prebuilt dist/ but no lockfile; lock generated from the
  # published package.json minus devDependencies/scripts (bun build tooling).
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    ${lib.getExe' nodejs_22 "node"} -e '
      const f = "package.json", p = JSON.parse(require("fs").readFileSync(f));
      delete p.devDependencies; delete p.scripts;
      require("fs").writeFileSync(f, JSON.stringify(p, null, 2));
    '
  '';

  npmDepsHash = "sha256-kT9umRNAgGmK8z95lrhdvzH+G//4QR3RE/3VBeDqQGE=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  # Self-update would npm install -g over the nix store copy.
  makeWrapperArgs = [
    "--set-default OPENCODE_BROWSER_AUTO_UPDATE off"
    "--set-default OPENCODE_BROWSER_UPDATE_CHECK 0"
  ];

  meta = {
    description = "MCP server + Chromium extension relay letting agents drive your real browser";
    homepage = "https://opencode.ai/product/browse";
    license = lib.licenses.mit;
    mainProgram = "browse";
  };
}
