{ options
, config
, lib
, ...
}:

with lib;
with lib.modernage;
let cfg = config.modernage.system.xkb;
in
{
  options.modernage.system.xkb = with types; {
    enable = mkBoolOpt false "Whether or not to configure xkb.";
  };

  config = mkIf cfg.enable {
    console.useXkbConfig = true;
    services.xserver = {
      layout = "us";
    };
  };
}
