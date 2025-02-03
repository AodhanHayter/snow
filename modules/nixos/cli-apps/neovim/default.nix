{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.cli-apps.neovim;
in
{
  options.modernage.cli-apps.neovim = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable neovim configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neovim
    ];

    environment.variables = {
      PAGER = "less";
      MANPAGER = "less";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    modernage.home = {
      extraOptions = {
        programs.zsh.shellAliases.vimdiff = "nvim -d";
        programs.bash.shellAliases.vimdiff = "nvim -d";
        programs.fish.shellAliases.vimdiff = "nvim -d";
      };
    };
  };
}
