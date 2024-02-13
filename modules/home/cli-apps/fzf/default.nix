{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.fzf;
in
{
  options.modernage.cli-apps.fzf = {
    enable = mkBoolOpt false "Whether or not to install and configure fzf.";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
