{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.apps.gnucash;
in
{
  options.modernage.apps.gnucash = {
    enable = mkBoolOpt false "Whether or not to install gnucash.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ gnucash ];
  };
}
