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
    };

    apps = {
      alacritty = enabled;
      obs-studio = enabled;
      gnucash = enabled;
      ghostty = enabled;
    };

    cli-apps = {
      autojump = enabled;
      awscli = enabled;
      bat = enabled;
      eza = enabled;
      fzf = enabled;
      gh = enabled;
      helm = enabled;
      home-manager = enabled;
      kubectl = enabled;
      neovim = enabled;
      password-store = enabled;
      tealdeer = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
      tmux = enabled;
      devenv = enabled;
      node = enabled;
    };
  };
}
