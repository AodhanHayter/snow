{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.ghostty;
  ghosttyConfig = ''
    theme = nord
    font-size = 16
  '';
in
{
  options.modernage.apps.ghostty = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure Ghostty.";
  };

  config = mkIf cfg.enable {
    # Ghostty doesn't package a darwin build for ghostty because of how macos binary distribution works
    # manually installing is best for MacOS right now
    home.packages = if pkgs.stdenv.isLinux then [ pkgs.ghostty ] else [ ];

    xdg.configFile = {
      "ghostty/config".text = ghosttyConfig;
    };
  };
}
