{
  lib,
  config,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.zellij;
  zellijConfig = ''
    theme "${cfg.theme}"
    keybinds {
      normal {
        unbind "Ctrl b"
        bind "Ctrl a" { SwitchToMode "tmux"; }
      }
    }
  '';
in
{
  options.modernage.tools.zellij = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure zellij.";
    theme = mkOpt str "nord" "Which zellij theme to enable.";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "zellij/config.kdl".text = zellijConfig;
    };

    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
