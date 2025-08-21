{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.make;
in
{
  options.modernage.tools.make = {
    enable = mkBoolOpt false "Whether or not to install and configure make.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gnumake ];
  };
}
