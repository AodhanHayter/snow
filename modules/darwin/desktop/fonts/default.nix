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
  cfg = config.modernage.desktop.fonts;
in
{
  options.modernage.desktop.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to enable custom fonts.";
  };

  config = mkIf cfg.enable {
    fonts.packages = [ pkgs.berkeley-mono ];
  };
}
