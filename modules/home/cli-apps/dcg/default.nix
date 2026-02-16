{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.dcg;
in
{
  options.modernage.cli-apps.dcg = {
    enable = mkBoolOpt false "Enable destructive command guard (dcg)";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.self.packages.${pkgs.system}.dcg ];
  };
}
