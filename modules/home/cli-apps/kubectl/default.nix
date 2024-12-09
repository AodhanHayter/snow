{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.kubectl;
in
{
  options.modernage.cli-apps.kubectl = {
    enable = mkBoolOpt false "Whether or not to install and configure kubectl.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ kubectl ];
    home.shellAliases = { k = "kubectl"; };
  };
}
