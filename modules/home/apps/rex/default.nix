{
  lib,
  config,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.rex;
in
{
  options.modernage.apps.rex = {
    enable = mkBoolOpt false "Whether or not to configure Rex (tmux-style keybinds).";
  };

  # Rex app is installed manually; this only manages its config.
  # Run `rex config reload` after switching.
  config = mkIf cfg.enable {
    xdg.configFile."rex/init.lua".source = ./init.lua;
  };
}
