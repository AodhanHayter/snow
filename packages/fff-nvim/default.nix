{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  inputs,
  system,
  vimUtils,
  ...
}:
let
  fffLib = inputs.self.packages.${system}.fff-nvim-lib;
  libname = if stdenvNoCC.hostPlatform.isDarwin then "libfff_nvim.dylib" else "libfff_nvim.so";
in
vimUtils.buildVimPlugin {
  pname = "fff-nvim";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "dmtrKovalenko";
    repo = "fff";
    rev = "4c5c92ac38364032e71e11d6adf49c8a326dcde8";
    hash = "sha256-a7L7zHXXRO6OyH7th4/8t79mTRz+jRtoPPBBMDUdDEQ=";
  };

  nvimSkipModule = [ "empty_config" ];

  postInstall = ''
    mkdir -p $out/target/release
    ln -s ${fffLib}/release/${libname} $out/target/release/${libname}
  '';

  meta = {
    description = "File search toolkit for Neovim with frecency ranking";
    homepage = "https://github.com/dmtrKovalenko/fff";
    license = lib.licenses.mit;
  };
}
