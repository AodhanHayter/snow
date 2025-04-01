{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.node;
in
{
  options.modernage.tools.node = {
    enable = mkBoolOpt false "Whether or not to install and configure nodejs.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ nodejs_23 ];
  };
}

