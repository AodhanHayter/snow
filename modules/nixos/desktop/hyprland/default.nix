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
  cfg = config.modernage.desktop.hyprland;
  user = config.modernage.user;
in
{
  options.modernage.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to use Hyprland as the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    programs.hyprlock.enable = true;
    programs.nm-applet.enable = true; # NetworkManager applet for managing network connections

    services.hypridle.enable = true;

    services.displayManager.defaultSession = "hyprland-uwsm";
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs; [
        kdePackages.qtsvg
        kdePackages.qtmultimedia
        kdePackages.qtvirtualkeyboard
      ];
      theme = "sddm-astronaut-theme";
      wayland.enable = true;
      enableHidpi = true;
      autoNumlock = true;
    };

    services.libinput.enable = true;
    services.gnome.gnome-keyring.enable = true;

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs; [
      bluetui # Bluetooth management tool
      btop # system resource monitor
      dunst # lightweight notification daemon
      hyprpaper # wallpaper setter for Hyprland
      hyprpicker # color picker for Hyprland
      hyprshot # screenshot tool for Hyprland
      hyprsunset # blue light filter for Hyprland
      kitty # required for the default Hyprland config
      libnotify # needed for dunst
      nautilus # file manager (optional, can be replaced with yazi)
      pavucontrol # volume control GUI
      quickshell
      rofi-wayland # application launcher for Hyprland
      waybar # status bar for Hyprland
      (sddm-astronaut.override { embeddedTheme = "pixel_sakura"; })
      yazi # tui file manager for Hyprland
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    hardware = {
      graphics.enable = true;
      nvidia.modesetting.enable = true;
    };
  };
}
