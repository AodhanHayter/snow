{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.tmux;

  themePlugins = {
    nord = pkgs.tmuxPlugins.nord;
    catppuccin = pkgs.tmuxPlugins.catppuccin;
    dracula = pkgs.tmuxPlugins.dracula;
    tokyo-night = pkgs.tmuxPlugins.tokyo-night-tmux;
    gruvbox = pkgs.tmuxPlugins.gruvbox;
    onedark = pkgs.tmuxPlugins.onedark-theme;
  };

  themePlugin = if cfg.theme != null then [ themePlugins.${cfg.theme} ] else [];
in
{
  options.modernage.tools.tmux = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure tmux.";
    theme = mkOpt (nullOr (enum [ "nord" "catppuccin" "dracula" "tokyo-night" "gruvbox" "onedark" ])) "nord"
      "Tmux color theme. Set to null to disable.";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      plugins = themePlugin;
      extraConfig = (builtins.readFile ./tmux.conf);
    };

    programs.zsh.initContent = ''
      function tm() {
        [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
        if [ $1 ]; then
           tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
        fi
        session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
      }
    '';

    programs.fish.functions.tm = ''
      if set -q TMUX
        set change switch-client
      else
        set change attach-session
      end
      if test (count $argv) -gt 0
        tmux $change -t "$argv[1]" 2>/dev/null; or begin
          tmux new-session -d -s $argv[1]; and tmux $change -t "$argv[1]"
        end
        return
      end
      set session (tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0)
      and tmux $change -t "$session"
      or echo "No sessions found."
    '';
  };
}
