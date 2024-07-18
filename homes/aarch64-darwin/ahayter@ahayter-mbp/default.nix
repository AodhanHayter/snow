{ lib
, pkgs
, config
, osConfig ? { }
, format ? "unknown"
, ...
}:

with lib.modernage;
{
  modernage = {
    user = {
      enable = true;
      name = "ahayter";
    };

    apps = {
      alacritty = {
        enable = true;
      };
    };

    cli-apps = {
      autojump = enabled;
      awscli = enabled;
      bat = enabled;
      eza = enabled;
      fzf = enabled;
      gh = enabled;
      home-manager = enabled;
      neovim = enabled;
      password-store = enabled;
      pulumi = enabled;
      ripgrep = enabled;
      zsh = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
      tmux = enabled;
      devenv = enabled;
    };
  };

  home.stateVersion = "22.11";
}
