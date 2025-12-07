{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.beads;
in
{
  options.modernage.cli-apps.beads = {
    enable = mkBoolOpt false "Whether or not to install beads (bd) - AI coding agent memory system.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ beads ];
  };
}
