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

    cli-apps = {
      fish = enabled;
      starship = enabled;
      zoxide = enabled;
      bat = enabled;
      claude-code = enabled;
      codex-cli = enabled;
      eza = enabled;
      fd = enabled;
      fzf = enabled;
      gh = enabled;
      home-manager = enabled;
      jq = enabled;
      neovim = enabled;
      ripgrep = enabled;
      ssh = enabled;
      tealdeer = enabled;
      yq = enabled;
    };

    shell = enabled;

    tools = {
      git = enabled;
      node = enabled;
      tmux = enabled;
    };
  };
}
