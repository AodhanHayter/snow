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
  cfg = config.modernage.apps.google-chrome;
in
{
  options.modernage.apps.google-chrome = with types; {
    enable = mkBoolOpt false "Whether or not to enable Google Chrome.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.google-chrome ];

    modernage.home = {
      extraOptions = {
        programs.browserpass = {
          enable = true;
          browsers = [
            "chrome"
          ];
        };
      };
    };
  };
}
