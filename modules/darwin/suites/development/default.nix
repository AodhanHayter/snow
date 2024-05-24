{ options
, config
, lib
, pkgs
, ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.suites.development;
in
{
  options.modernage.suites.development = with types; {
    enable = mkBoolOpt false "Whether or not to enable development configuration.";
  };

  config = mkIf cfg.enable {
    modernage = {
      tools = {
        docker = enabled;
      };
    };
  };
}
