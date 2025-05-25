{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.nodejs;
in
{
  options.modernage.tools.nodejs = with types; {
    enable = mkBoolOpt false "Wheter or not to enable nodejs configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nodejs_24
    ];
  };
}
