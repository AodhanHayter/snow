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
    };

    tools = {
      git = enabled;
      direnv = enabled;
      tmux = enabled;
    };
  };
}
