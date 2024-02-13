{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.password-store;
in
{
  options.modernage.cli-apps.password-store = {
    enable = mkBoolOpt false "Whether or not to install and configure password-store.";
  };

  config = mkIf cfg.enable {
    programs.password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "$HOME/.password-store";
      };
    };
  };
}
