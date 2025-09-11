{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.neovim;
in
{
  options.modernage.cli-apps.neovim = {
    enable = mkBoolOpt false "Whether or not to install and configure neovim.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gcc # treesitter needs a c compiler
      yarn # used by the nvim nodejs provider
      # Various language servers
      expert
      dockerfile-language-server-nodejs
      lua-language-server
      marksman
      nixd
      nixpkgs-fmt
      diagnostic-languageserver
      bash-language-server
      typescript-language-server
      basedpyright
      terraform-ls
      vscode-langservers-extracted
      ###
    ];

    # link configuration files so nvim can find them.
    xdg.configFile."nvim/lua" = {
      source = ./config/lua;
      recursive = true;
    };

    xdg.configFile."nvim/lsp" = {
      source = ./config/lsp;
      recursive = true;
    };

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withPython3 = true;
      extraLuaConfig = ''
        ${lib.strings.fileContents ./config/init.lua}
      '';
    };
  };
}
