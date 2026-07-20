{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "beads-rust";
  version = "0.2.18";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "beads_rust";
    rev = "v${version}";
    hash = "sha256-xKPESzBHXHP89KddtfeaW963Z89Wc9mi6u6tMXaACjI=";
  };

  # Upstream's committed Cargo.lock pins fsqlite-* to sourceless local entries
  # (leftover path override to the author's frankensqlite checkout), which cargo
  # can't resolve offline. Regenerated clean from crates.io, with asupersync
  # held at 0.3.6: fsqlite 0.1.16 calls the 1-arg `try_acquire`, but asupersync
  # 0.3.9 broke that to 2-arg in a patch release, so the default resolution
  # fails to compile.
  cargoLock = {
    lockFile = ./Cargo.lock;
  };
  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  # Tests shell out / hit network (assert_cmd, self-update); build only.
  doCheck = false;

  meta = {
    description = "Agent-first issue tracker (SQLite + JSONL) - Rust port of beads";
    homepage = "https://github.com/Dicklesworthstone/beads_rust";
    license = lib.licenses.mit;
    mainProgram = "br";
    platforms = lib.platforms.unix;
  };
}
