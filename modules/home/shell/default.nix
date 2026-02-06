{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.shell;
  shellPkg =
    if cfg.default == "fish"
    then pkgs.fish
    else pkgs.zsh;
in
{
  options.modernage.shell = {
    enable = mkBoolOpt false "Whether or not to enable shell orchestration.";
    default = mkOpt (types.enum [ "fish" "zsh" ]) "fish" "Default login shell.";
  };

  config = mkIf cfg.enable {
    home.sessionVariables.SHELL = "${shellPkg}/bin/${cfg.default}";
  };
}
