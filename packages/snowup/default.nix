{
  lib,
  rustPlatform,
  makeWrapper,
  fzf,
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

  nativeBuildInputs = [ makeWrapper ];

  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/snowup --prefix PATH : ${lib.makeBinPath [ fzf ]}
    ln -s snowup $out/bin/up
  '';

  meta = {
    description = "Flake update + rebuild driver with fzf-based selection";
    homepage = "https://github.com/AodhanHayter/snow";
    license = lib.licenses.mit;
    mainProgram = "snowup";
  };
}
