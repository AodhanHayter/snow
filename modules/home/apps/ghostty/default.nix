{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.ghostty;
  ghosttyConfig = ''
    theme = nord
    font-size = 16
    cursor-style = block
    mouse-hide-while-typing = true
    macos-titlebar-style = transparent
    copy-on-select = clipboard

    # keybindings

    ## windows
    keybind = ctrl+a>n=new_window

    ## tabs
    keybind = ctrl+a>c=new_tab
    keybind = ctrl+a>n=next_tab
    keybind = ctrl+a>p=previous_tab

    ## splits

    keybind = ctrl+a>shift+'=new_split:down
    keybind = ctrl+a>shift+5=new_split:right

    keybind = ctrl+a>j=goto_split:bottom
    keybind = ctrl+a>k=goto_split:top
    keybind = ctrl+a>h=goto_split:left
    keybind = ctrl+a>l=goto_split:right
  '';
in
{
  options.modernage.apps.ghostty = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure Ghostty.";
  };

  config = mkIf cfg.enable {
    # Ghostty doesn't package a darwin build for ghostty because of how macos binary distribution works
    # manually installing is best for MacOS right now
    home.packages = if pkgs.stdenv.isLinux then [ pkgs.ghostty ] else [ ];

    xdg.configFile = {
      "ghostty/config".text = ghosttyConfig;
    };
  };
}
