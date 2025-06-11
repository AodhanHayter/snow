{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.claude-code;
in
{
  options.modernage.cli-apps.claude-code = {
    enable = mkBoolOpt false "Whether or not to install and configure claude code.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [claude-code];
    programs.bat = {
      enable = true;
    };
  };
}
