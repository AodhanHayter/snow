{
  options,
  config,
  lib,
  ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.devenv;
in
{
  options.modernage.tools.devenv = with types; {
    enable = mkBoolOpt false "Whether or not to enable devenv.";
  };

  config = mkIf cfg.enable {
    programs.devenv = {
      enable = true;
      enableFishIntegration = config.modernage.cli-apps.fish.enable;
    };
  };
}
