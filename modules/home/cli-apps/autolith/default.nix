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
  cfg = config.modernage.cli-apps.autolith;
in
{
  options.modernage.cli-apps.autolith = {
    enable = mkBoolOpt false "Whether or not to install autolith.";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.autolith.packages.${pkgs.stdenv.hostPlatform.system}.autolith ];
  };
}
