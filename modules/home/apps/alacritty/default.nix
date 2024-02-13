{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.alacritty;
in
{
  options.modernage.apps.alacritty = {
    enable = mkBoolOpt false "Whether or not to install and configure Alacritty.";
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        custom_cursor_colors = true;
        font = {
          size = 14;
          normal = {
            family = "FiraCode Nerd Font";
          };
        };

        colors = {

          primary = {
            background = "0x3c4c55";
            forground = "0xc5d4dd";
          };

          cursor = {
            text = "0x3c4c55";
            cursor = "0x7fc1ca";
          };

          normal = {
            black = "0x3c4c55";
            red = "0xdf8c8c";
            green = "0xa8ce93";
            yellow = "0xdada93";
            blue = "0x83afe5";
            magenta = "0x9a93e1";
            cyan = "0x7fc1ca";
            white = "0xc5d4dd";
          };

          bright = {
            black = "0x899ba6";
            red = "0xf2c38f";
            green = "0xa8ce93";
            yellow = "0xdada93";
            blue = "0x83afe5";
            magenta = "0xd18ec2";
            cyan = "0x7fc1ca";
            white = "0xe6eef3";
          };
        };
      };
    };
  };
}
