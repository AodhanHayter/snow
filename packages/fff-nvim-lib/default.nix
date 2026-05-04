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
      asset = "aarch64-apple-darwin.dylib";
      libname = "libfff_nvim.dylib";
      hash = "sha256-6HiAhhfkGEJVVEZMdiQXZO5S6m/WtK22tYrpUH2JXoU=";
    };
    "x86_64-linux" = {
      asset = "x86_64-unknown-linux-gnu.so";
      libname = "libfff_nvim.so";
      hash = "sha256-93uaOPeRM0kYa8SYMHJKKVERyNPXH+D1jsAwDd1IGO8=";
    };
  };

  platform = platforms.${system} or (throw "fff-nvim-lib: unsupported system ${system}");
  version = "0.7.0";
in
stdenvNoCC.mkDerivation {
  pname = "fff-nvim-lib";
  inherit version;

  src = fetchurl {
    url = "https://github.com/dmtrKovalenko/fff/releases/download/v${version}/${platform.asset}";
    hash = platform.hash;
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/release
    install -Dm755 $src $out/release/${platform.libname}
  '';

  meta = {
    description = "Prebuilt Rust shared library for fff.nvim";
    homepage = "https://github.com/dmtrKovalenko/fff";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
