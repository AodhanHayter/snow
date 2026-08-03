{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.grok;
in
{
  options.modernage.cli-apps.grok = {
    enable = mkBoolOpt false "Whether or not to install grok.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ grok ];
  };
}
