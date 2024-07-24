{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.pulumi;
in
{
  options.modernage.cli-apps.pulumi = {
    enable = mkBoolOpt false "Whether or not to install and configure pulumi.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ pulumi ];
  };
}
