{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.brave;
in
{
  options.modernage.apps.brave = with types; {
    enable = mkBoolOpt false "Whether or not to enable Brave.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.brave ];

    modernage.home = {
      extraOptions = {
        programs.browserpass = {
          enable = true;
          browsers = [ "brave" "chrome" "firefox" ];
        };
      };
    };
  };
}
