{ lib, config, pkgs, ... }:

with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.gemini-cli;
in
{
  options.modernage.cli-apps.gemini-cli = with types; {
    enable = mkBoolOpt false "Enable the gemini CLI";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ gemini-cli ];
  };
}