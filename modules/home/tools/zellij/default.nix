{
  lib,
  config,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.zellij;
in
{
  options.modernage.tools.zellij = {
    enable = mkBoolOpt false "Whether or not to install and configure zellij.";
  };

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      settings = {
        theme = "nord";
      };
    };
  };
}
