{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.opencode;
in
{
  options.modernage.cli-apps.opencode = {
    enable = mkBoolOpt false "Whether or not to install and configure opencode.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ opencode ];
  };
}
