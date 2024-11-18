{ lib, config, pkgs, ... }:
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
      # Various language servers
      dockerfile-language-server-nodejs
      lua-language-server
      marksman
      nixd
      nixpkgs-fmt
      nodePackages.bash-language-server
      nodePackages.diagnostic-languageserver
      nodePackages.typescript-language-server
      pyright
      terraform-ls
      ###
    ];

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withPython3 = true;
      extraConfig = ''
        lua << EOF
        ${lib.strings.fileContents ./config/settings.lua}
        ${lib.strings.fileContents ./config/maps.lua}
        ${lib.strings.fileContents ./config/plugins-lazy.lua}
      '';
    };
  };
}
