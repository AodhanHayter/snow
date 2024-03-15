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
        theme = "solarized_light";
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
      zsh = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
      tmux = enabled;
    };
  };

  home.stateVersion = "22.11";
}
