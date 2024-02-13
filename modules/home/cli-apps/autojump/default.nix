{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.autojump;
in
{
  options.modernage.cli-apps.autojump = {
    enable = mkBoolOpt false "Whether or not to install and configure autojump.";
  };

  config = mkIf cfg.enable {
    programs.autojump = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
