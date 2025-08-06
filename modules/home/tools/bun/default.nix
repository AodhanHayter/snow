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
  cfg = config.modernage.tools.bun;
in
{
  options.modernage.tools.bun = with types; {
    enable = mkBoolOpt false "Whether or not to enable bun.";
  };

  config = mkIf cfg.enable {
    programs.bun.enable = true;
  };
}
