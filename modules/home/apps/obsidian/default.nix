{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.obsidian;
in
{
  options.modernage.apps.obsidian = {
    enable = mkBoolOpt false "Whether or not to install and configure Obsidian.";
  };

  config = mkIf cfg.enable {
    programs.obsidian = {
      enable = true;
      cli.enable = true;
    };
  };
}
