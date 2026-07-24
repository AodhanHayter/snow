{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  ...
}:
buildNpmPackage rec {
  pname = "codex-acp";
  version = "1.1.7";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    rev = "v${version}";
    hash = "sha256-RY1iiajNR3eJI9WYARZnbIHnDl5+gmlPo3GVjJEJ9Zs=";
  };

  npmDepsHash = "sha256-c/sbGziA3Y2mOcPRD3K0PSd8sAVXSQuip8fE/eojl+Y=";

  # build.mjs (esbuild) bundles src/index.ts -> dist/index.js; bin = dist/index.js
  npmBuildScript = "build";

  dontCheckForBrokenSymlinks = true;

  meta = {
    description = "Codex agent exposed over the Agent Client Protocol";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
  };
}
