{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.zoxide;
in
{
  options.modernage.cli-apps.zoxide = {
    enable = mkBoolOpt false "Whether or not to install and configure zoxide.";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
