{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.modernage;
let cfg = config.modernage.system.input;
in
{
  options.modernage.system.input = with types; {
    enable = mkEnableOption "Enable Macos system input config";
  };

  config = mkIf cfg.enable {
    system.defaults = {
      NSGlobalDomain = {
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
    };
  };
}
