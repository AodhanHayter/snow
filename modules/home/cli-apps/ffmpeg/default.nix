{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.ffmpeg;
in
{
  options.modernage.cli-apps.ffmpeg = {
    enable = mkBoolOpt false "Whether or not to install ffmpeg.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.ffmpeg ];
  };
}
