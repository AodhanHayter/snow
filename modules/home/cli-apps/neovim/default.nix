{
  lib,
  config,
  pkgs,
  inputs,
  system,
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
      astro-language-server
      dockerfile-language-server
      expert
      lua-language-server
      marksman
      nil
      nixd
      nixpkgs-fmt
      diagnostic-languageserver
      bash-language-server
      typescript-language-server
      terraform-ls
      ty
      vscode-langservers-extracted
      yaml-language-server
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
      withRuby = false; # adopt HM 26.05 default (no ruby provider)
      initLua = ''
        vim.g.fff_nvim_dir = "${inputs.self.packages.${system}.fff-nvim}"
        ${lib.strings.fileContents ./config/init.lua}
      '';
    };
  };
}
