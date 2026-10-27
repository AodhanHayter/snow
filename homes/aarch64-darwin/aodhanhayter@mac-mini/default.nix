{
  lib,
  pkgs,
  inputs,
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
      rex = enabled;
      obsidian = enabled;
    };

    cli-apps = {
      agent-browser = enabled;
      ast-grep = enabled;
      fish = enabled;
      starship = enabled;
      zoxide = enabled;
      awscli = enabled;
      bat = enabled;
      claude-code = enabled;
      codex-cli = enabled;
      dcg = enabled;
      dog = enabled;
      entr = enabled;
      eza = enabled;
      fd = enabled;
      ffmpeg = enabled;
      fzf = enabled;
      gemini-cli = disabled;
      gh = enabled;
      gogcli = enabled;
      grok = enabled;
      herdr = {
        enable = true;
        plugins.agent-usage = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-agent-usage;
      };
      home-manager = enabled;
      hunk = enabled;
      jq = enabled;
      neovim = enabled;
      opencode = enabled;
      password-store = enabled;
      perles = enabled;
      pi = enabled;
      pulumi = enabled;
      ripgrep = enabled;
      ssh = enabled;
      tealdeer = enabled;
      worktrunk = enabled;
      yq = enabled;
      zsh = disabled;
    };

    security.gpg-unlock = {
      enable = true;
      keygrips = [
        "6E8A6A4863276BD9ABE492016C252A2188C6EE30" # master
        "6F4B0E5EDC30EFCE840B549EE4AAB0DBACB6E943" # 2026 [S]
        "0E9147D59A2C4CBC2A8248C83EDC30369535B4E8" # 2026 [E]
      ];
    };

    shell = enabled;

    tools = {
      devenv = enabled;
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
