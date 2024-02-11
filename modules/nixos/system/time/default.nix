{ options
, config
, pkgs
, lib
, ...
}:

with lib;
with lib.modernage;
let cfg = config.modernage.system.time;
in
{
  options.modernage.system.time = with types; {
    enable =
      mkBoolOpt false "Whether or not to configure timezone information.";
  };

  config = mkIf cfg.enable { time.timeZone = "America/Denver"; };
}
