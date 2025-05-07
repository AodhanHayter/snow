{
  lib,
  pkgs,
  ...
}:

with lib.modernage;
{
  modernage = {
    user = {
      enable = true;
      name = "aodhanhayter";
    };

    apps = {
      alacritty = {
        enable = true;
      };
      ghostty = enabled;
    };

    cli-apps = {
      autojump = enabled;
      awscli = enabled;
      bat = enabled;
      dog = enabled;
      entr = enabled;
      eza = enabled;
      fd = enabled;
      fzf = enabled;
      gh = enabled;
      home-manager = enabled;
      jq = enabled;
      neovim = enabled;
      opencode = enabled;
      password-store = enabled;
      # pulumi = enabled;
      tealdeer = enabled;
      ripgrep = enabled;
      zsh = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
      tmux = enabled;
      zellij = enabled;
      devenv = enabled;
    };
  };

  home.stateVersion = "22.11";
}
