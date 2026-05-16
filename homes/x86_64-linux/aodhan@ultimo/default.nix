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
      gemini-cli = disabled;
      gh = enabled;
      gogcli = enabled;
      home-manager = enabled;
      jq = enabled;
      neovim = enabled;
      opencode = enabled;
      password-store = enabled;
      pulumi = enabled;
      ripgrep = enabled;
      ssh = enabled;
      tealdeer = enabled;
      yq = enabled;
      zsh = enabled;
    };

    security = {
      keyring-unlock = enabled;
      gpg-unlock = {
        enable = true;
        keygrips = [
          "6E8A6A4863276BD9ABE492016C252A2188C6EE30" # master
          "BB9C625BADD5C82424D600299591D8458053D338" # 2026 [S]
          "A1E94F33D0EE4F8734240B990B99C86D48DBD214" # 2026 [E]
          "6F4B0E5EDC30EFCE840B549EE4AAB0DBACB6E943" # 2026 [S]
          "0E9147D59A2C4CBC2A8248C83EDC30369535B4E8" # 2026 [E]
        ];
      };
    };

    shell = enabled;

    tools = {
      devenv = enabled;
      git = enabled;
      mcp-servers = enabled;
      node = enabled;
      sops = enabled;
      tmux = enabled;
      bun = enabled;
    };
  };
}
