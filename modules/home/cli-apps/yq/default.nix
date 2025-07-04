{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.yq;
in
{
  options.modernage.cli-apps.yq = {
    enable = mkBoolOpt false "Whether or not to install and configure yq.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ yq-go ]; # use the go version as its a single binary install
  };
}
