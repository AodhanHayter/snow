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
      node = enabled;
      sops = enabled;
      tmux = enabled;
      bun = enabled;
    };
  };
}
