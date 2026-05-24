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
  cfg = config.modernage.cli-apps.snowup;
in
{
  options.modernage.cli-apps.snowup = {
    enable = mkBoolOpt false "Whether or not to install snowup (flake update + rebuild TUI).";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.snowup ];
  };
}
