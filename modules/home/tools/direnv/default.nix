{ options, config, lib, pkgs, ... }:

with lib;
with lib.modernage;
let cfg = config.modernage.tools.direnv;
in
{
  options.modernage.tools.direnv = with types; {
    enable = mkBoolOpt false "Whether or not to enable direnv.";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = enabled;
    };
  };
}
