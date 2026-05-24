{
  lib,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "snowup";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      name: type:
      let
        base = baseNameOf (toString name);
      in
      base != "target" && base != "result";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  doCheck = false;

  postInstall = ''
    ln -s snowup $out/bin/up
  '';

  meta = {
    description = "TUI for reviewing flake.lock updates and rebuilding the modernage host";
    homepage = "https://github.com/AodhanHayter/snow";
    license = lib.licenses.mit;
    mainProgram = "snowup";
  };
}
