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
in
{
  options.modernage.apps.ghostty = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure Ghostty.";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;

      # Ghostty doesn't package a darwin build because of how macos binary
      # distribution works; install the app manually there. package = null keeps
      # the config managed while skipping the (unavailable) nixpkgs build.
      package = if pkgs.stdenv.isLinux then pkgs.ghostty else null;

      settings = {
        theme = "nord";
        font-family = "Berkeley Mono";
        font-size = 16;
        cursor-style = "block";
        mouse-hide-while-typing = true;
        macos-titlebar-style = "transparent";
        copy-on-select = "clipboard";
        quick-terminal-position = "bottom";
        shell-integration = "fish";
        shell-integration-features = "cursor,sudo,title,ssh-terminfo,ssh-env";

        auto-update-channel = "stable";

        keybind = [
          # windows
          "ctrl+g>n=new_window"
          # tabs
          "ctrl+g>c=new_tab"
          "ctrl+g>n=next_tab"
          "ctrl+g>p=previous_tab"
          # splits
          "ctrl+g>shift+'=new_split:down"
          "ctrl+g>shift+5=new_split:right"
          "ctrl+g>e=equalize_splits"
          "ctrl+g>j=goto_split:bottom"
          "ctrl+g>k=goto_split:top"
          "ctrl+g>h=goto_split:left"
          "ctrl+g>l=goto_split:right"
          # shortcuts
          "ctrl+g>q=toggle_quick_terminal"
        ];
      };
    };
  };
}
