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
  cfg = config.modernage.cli-apps.hunk;
in
{
  options.modernage.cli-apps.hunk = {
    enable = mkBoolOpt false "Whether or not to install hunk.";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk ];
  };
}
