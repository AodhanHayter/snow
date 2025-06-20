{
  lib,
  pkgs,
  config,
  osConfig ? { },
  format ? "unknown",
  ...
}:
with lib.modernage;
{
  modernage = {
    user = {
      enable = true;
    };

    apps = {
      ghostty = enabled;
      gnucash = enabled;
      obs-studio = enabled;
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
      devenv = enabled;
      direnv = enabled;
      git = enabled;
      node = enabled;
      sops = enabled;
      tmux = enabled;
    };
  };
}
