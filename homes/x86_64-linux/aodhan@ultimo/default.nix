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

    hyprland = enabled;

    apps = {
      ghostty = enabled;
      gnucash = enabled;
      obs-studio = enabled;
      omnissa-horizon-client = enabled;
    };

    cli-apps = {
      ast-grep = enabled;
      fish = enabled;
      starship = enabled;
      zoxide = enabled;
      awscli = disabled;
      bat = enabled;
      claude-code = enabled;
      codex-cli = enabled;
      dcg = enabled;
      dog = enabled;
      entr = enabled;
      eza = enabled;
      fd = enabled;
      fzf = enabled;
      gemini-cli = enabled;
      gh = enabled;
      gogcli = enabled;
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
      node = enabled;
      sops = enabled;
      tmux = enabled;
      bun = enabled;
    };
  };
}
