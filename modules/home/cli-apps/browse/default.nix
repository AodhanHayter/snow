{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.browse;
in
{
  options.modernage.cli-apps.browse = {
    enable = mkBoolOpt false "Whether or not to install the browse CLI (pairing, doctor).";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.browse ];
  };
}
