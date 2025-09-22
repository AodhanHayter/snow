{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.hyprland;
in
{
  options.modernage.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprland configuration.";
  };

  config = mkIf cfg.enable {
    xdg.configFile.hypr = {
      source = ./hypr;
      recursive = true;
    };
  };
}
