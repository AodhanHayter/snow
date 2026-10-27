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
  cfg = config.modernage.cli-apps.perles;
in
{
  options.modernage.cli-apps.perles = {
    enable = mkBoolOpt false "Whether or not to install perles.";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.perles-nix.packages.${pkgs.stdenv.hostPlatform.system}.perles ];
  };
}
