{
  lib,
  config,
  pkgs,
  ...
}:
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
    # dogdns removed in nixos-26.05 (unmaintained upstream); doggo is the recommended replacement
    home.packages = with pkgs; [ doggo ];
  };
}
