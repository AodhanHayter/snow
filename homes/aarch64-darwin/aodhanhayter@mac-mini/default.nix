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
      ghostty = enabled;
    };

    cli-apps = {
      ast-grep = enabled;
      autojump = enabled;
      awscli = enabled;
      bat = enabled;
      beads = enabled;
      beads-viewer = enabled;
      claude-code = enabled;
      codex-cli = enabled;
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
      pulumi = enabled;
      tealdeer = enabled;
      ripgrep = enabled;
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
    };
  };

  home.stateVersion = "22.11";
}
