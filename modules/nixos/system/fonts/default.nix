{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.system.fonts;
in
{
  options.modernage.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = mkOpt (listOf package) [ ] "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };

    environment.systemPackages = with pkgs; [ font-manager ];

    fonts.packages =
      with pkgs;
      [
        font-awesome
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        nerd-fonts.hack
        nerd-fonts.fira-code
        nerd-fonts.meslo-lg
        roboto
      ]
      ++ cfg.fonts;
  };
}
