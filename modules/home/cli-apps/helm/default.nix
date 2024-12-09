{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.helm;
in
{
  options.modernage.cli-apps.helm = {
    enable = mkBoolOpt false "Whether or not to install and configure helm.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ kubernetes-helm ];
  };
}
