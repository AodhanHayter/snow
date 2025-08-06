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
      name = "ahayter";
    };

    apps = {
      ghostty = enabled;
    };

    cli-apps = {
      ast-grep = enabled;
      autojump = enabled;
      awscli = enabled;
      bat = enabled;
      claude-code = enabled;
      dog = enabled;
      entr = enabled;
      eza = enabled;
      fd = enabled;
      fzf = enabled;
      gemini-cli = enabled;
      gh = enabled;
      home-manager = enabled;
      jq = enabled;
      neovim = enabled;
      opencode = enabled;
      password-store = enabled;
      pulumi = enabled;
      ripgrep = enabled;
      tealdeer = enabled;
      yq = enabled;
      zsh = enabled;
    };

    tools = {
      devenv = enabled;
      direnv = enabled;
      git = enabled;
      mcp-servers = enabled;
      sops = enabled;
      tmux = enabled;
      bun = enabled;
    };
  };

  home.stateVersion = "22.11";
}
