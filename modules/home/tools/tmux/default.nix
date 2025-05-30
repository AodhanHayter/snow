{
  lib,
  config,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.tmux;
in
{
  options.modernage.tools.tmux = {
    enable = mkBoolOpt false "Whether or not to install and configure tmux.";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
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
  };
}
