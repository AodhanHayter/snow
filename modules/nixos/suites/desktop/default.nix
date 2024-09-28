{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.suites.desktop;
in
{
  options.modernage.suites.desktop = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = mkIf cfg.enable {
    modernage = {

      desktop = {
        plasma5 = enabled;
      };

      apps = {
        brave = enabled;
        protonvpn = enabled;
      };

      cli-apps = {
        neovim = enabled;
        tmux = enabled;
      };

      services = {
        avahi = enabled;
        interception-tools = enabled;
        printing = enabled;
        openssh = enabled;
      };

    };
  };
}
