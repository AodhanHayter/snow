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
  cfg = config.modernage.cli-apps.beads-rust;
  beads-rust = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.beads-rust;
in
{
  options.modernage.cli-apps.beads-rust = {
    enable = mkBoolOpt false "Whether or not to install beads-rust (br).";
  };

  config = mkIf cfg.enable {
    home.packages = [ beads-rust ];
  };
}
