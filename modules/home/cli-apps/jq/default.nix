{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.jq;
in
{
  options.modernage.cli-apps.jq = {
    enable = mkBoolOpt false "Whether or not to install and configure jq.";
  };

  config = mkIf cfg.enable {
    programs.jq = {
      enable = true;
    };
  };
}
