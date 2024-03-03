{ options
, config
, lib
, pkgs
, ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.suites.common;
in
{
  options.modernage.suites.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    programs.zsh = enabled;

    modernage = {
      nix = enabled;

      cli-apps = {
        neovim = enabled;
      };

      tools = {
        flake = enabled;
        git = enabled;
      };

      system = {
        fonts = enabled;
        input = enabled;
        interface = enabled;
      };

      security = {
        gpg = enabled;
      };
    };
  };
}
