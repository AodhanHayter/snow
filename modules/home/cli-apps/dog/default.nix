{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.dog;
in
{
  options.modernage.cli-apps.dog = {
    enable = mkBoolOpt false "Whether or not to install and configure dog.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ dogdns ];
  };
}
