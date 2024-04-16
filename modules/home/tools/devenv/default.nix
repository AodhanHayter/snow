{ options, config, lib, pkgs, ... }:

with lib;
with lib.modernage;
let cfg = config.modernage.tools.devenv;
in
{
  options.modernage.tools.devenv = with types; {
    enable = mkBoolOpt false "Whether or not to enable devenv.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ devenv ];
  };
}
