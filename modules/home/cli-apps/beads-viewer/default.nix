{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.beads-viewer;
in
{
  options.modernage.cli-apps.beads-viewer = {
    enable = mkBoolOpt false "Whether or not to install beads-viewer (bv) - TUI for Beads issue tracker.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ beads-viewer ];
  };
}
