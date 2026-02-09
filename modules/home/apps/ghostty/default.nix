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
    quick-terminal-position = bottom
    shell-integration = fish
    shell-integration-features = cursor,sudo,title,ssh-terminfo,ssh-env

    # set update channel to install from main
    # to get latest changes
    auto-update-channel = tip

    # keybindings
    ## windows
    keybind = ctrl+g>n=new_window

    ## tabs
    keybind = ctrl+g>c=new_tab
    keybind = ctrl+g>n=next_tab
    keybind = ctrl+g>p=previous_tab

    ## splits

    keybind = ctrl+g>shift+'=new_split:down
    keybind = ctrl+g>shift+5=new_split:right
    keybind = ctrl+g>e=equalize_splits

    keybind = ctrl+g>j=goto_split:bottom
    keybind = ctrl+g>k=goto_split:top
    keybind = ctrl+g>h=goto_split:left
    keybind = ctrl+g>l=goto_split:right

    # shortcuts
    keybind = ctrl+g>q=toggle_quick_terminal
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
