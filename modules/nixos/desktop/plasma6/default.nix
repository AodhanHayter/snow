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
  cfg = config.modernage.desktop.plasma6;
in
{
  options.modernage.desktop.plasma6 = with types; {
    enable = mkBoolOpt false "Whether or not to use KDE Plasma6 as the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libsForQt5.bismuth
    ];

    modernage.system.xkb.enable = true;

    services.desktopManager = {
      plasma6 = {
        enable = true;
      };
    };

    services.libinput.enable = true;
    services.displayManager.sddm.enable = true;

    programs.kdeconnect.enable = true;
  };
}
