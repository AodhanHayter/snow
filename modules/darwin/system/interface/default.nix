{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.modernage;
let cfg = config.modernage.system.interface;
in
{
  options.modernage.system.interface = with types; {
    enable = mkEnableOption "Enable Macos system interface config";
  };

  config = mkIf cfg.enable {
    system.defaults = {
      dock.autohide = true;

      finder = {
        AppleShowAllExtensions = true;
      };

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleShowScrollBars = "WhenScrolling";
      };
    };
  };
}
