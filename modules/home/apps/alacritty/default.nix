{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.alacritty;
  themeSrc = "${inputs.alacritty-themes}/themes";
in
{
  options.modernage.apps.alacritty = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure Alacritty.";
    theme = mkOpt str "github_dark" "What alacritty theme to enable. Sources from https://github.com/alacritty/alacritty-theme";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "alacritty/themes".source = themeSrc;
    };

    programs.alacritty = {
      enable = true;
      settings = {

        import = [ "~/.config/alacritty/themes/${cfg.theme}.yaml" ];

        font = {
          size = 16;
          normal = {
            family = "FiraCode Nerd Font";
          };
        };

      };
    };
  };
}
