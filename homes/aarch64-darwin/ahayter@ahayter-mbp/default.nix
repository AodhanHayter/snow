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
      fish = enabled;
      starship = enabled;
      zoxide = enabled;
      awscli = enabled;
      bat = enabled;
      claude-code = {
        enable = true;
        alerts = enabled;
      };
      codex-cli = enabled;
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

    shell = enabled;

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

  # Wake-on-LAN for waking ultimo
  home.packages = [ pkgs.wakeonlan ];
  home.shellAliases.wake-ultimo = "wakeonlan a8:a1:59:a8:d9:5f";

  home.stateVersion = "22.11";
}
