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
  cfg = config.modernage.cli-apps.beads-viewer;
  beads-viewer = inputs.self.packages.${pkgs.system}.beads-viewer;
in
{
  options.modernage.cli-apps.beads-viewer = {
    enable = mkBoolOpt false "Whether or not to install beads-viewer (bv) - TUI for Beads issue tracker.";
  };

  config = mkIf cfg.enable {
    home.packages = [ beads-viewer ];
  };
}
