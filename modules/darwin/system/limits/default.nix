{
  lib,
  config,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.system.limits;
in
{
  options.modernage.system.limits = {
    enable = mkBoolOpt true "Whether to configure system resource limits.";
    maxfiles = mkOpt types.int 524288 "Maximum number of open files.";
  };

  config = mkIf cfg.enable {
    launchd.daemons.limit-maxfiles = {
      script = ''
        /bin/launchctl limit maxfiles ${toString cfg.maxfiles} ${toString cfg.maxfiles}
      '';
      serviceConfig = {
        Label = "limit.maxfiles";
        RunAtLoad = true;
      };
    };
  };
}
