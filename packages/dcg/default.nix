{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  perl,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "dcg";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "destructive_command_guard";
    rev = "v${version}";
    hash = "sha256-tkjHhSMoLRV56AwUa0DkoDMoEj6gUZx/ih0VTC9C+4o=";
  };

  cargoHash = "sha256-G6cOjl5tLdjBg7A+Itnk/t6tLzoU7gKYOTYlZm3HSlA=";

  nativeBuildInputs = [ pkg-config cmake perl ];

  # vergen-gix needs git metadata; VERGEN_IDEMPOTENT provides fallback values in sandbox
  env.VERGEN_IDEMPOTENT = "1";

  # tests require git repo and network
  doCheck = false;

  meta = {
    description = "Hook for AI coding agents that blocks destructive commands";
    homepage = "https://github.com/Dicklesworthstone/destructive_command_guard";
    license = lib.licenses.mit;
    mainProgram = "dcg";
  };
}
