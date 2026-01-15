{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.gogcli;
  gogcli = inputs.self.packages.${pkgs.system}.gogcli;
in
{
  options.modernage.cli-apps.gogcli = {
    enable = mkBoolOpt false "Whether or not to install gogcli.";
  };

  config = mkIf cfg.enable {
    home.packages = [ gogcli ];
  };
}
