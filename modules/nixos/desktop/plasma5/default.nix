{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.desktop.plasma5;
in
{
  options.modernage.desktop.plasma5 = with types; {
    enable =
      mkBoolOpt false "Whether or not to use KDE Plasma5 as the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libsForQt5.bismuth
    ];

    modernage.system.xkb.enable = true;

    services.xserver = {
      enable = true;

      desktopManager = {
        plasma5 = {
          enable = true;
          useQtScaling = true;
        };
      };
    };

    services.libinput.enable = true;
    services.displayManager.sddm.enable = true;

    programs.kdeconnect.enable = true;
  };
}
