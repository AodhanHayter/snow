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
      obsidian = enabled;
    };

    cli-apps = {
      ast-grep = enabled;
      fish = enabled;
      starship = enabled;
      zoxide = enabled;
      awscli = enabled;
      bat = enabled;
      beads-rust = enabled;
      claude-code = enabled;
      codex-cli = enabled;
      dcg = enabled;
      dog = enabled;
      entr = enabled;
      eza = enabled;
      fd = enabled;
      fzf = enabled;
      gh = enabled;
      grok = enabled;
      home-manager = enabled;
      hunk = enabled;
      jq = enabled;
      neovim = enabled;
      omp = enabled;
      opencode = enabled;
      password-store = enabled;
      pi = enabled;
      pulumi = enabled;
      tealdeer = enabled;
      ripgrep = enabled;
      ssh = enabled;
      worktrunk = enabled;
      yq = enabled;
      zsh = enabled;
    };

    shell = enabled;

    tools = {
      devenv = enabled;
      git = enabled;
      mcp-servers = enabled;
      sops = enabled;
      tmux = enabled;
    };
  };

  # Wake-on-LAN for waking ultimo
  home.packages = [ pkgs.wakeonlan ];
  home.shellAliases.wake-ultimo = "wakeonlan a8:a1:59:a8:d9:5f";

  home.stateVersion = "22.11";
}
