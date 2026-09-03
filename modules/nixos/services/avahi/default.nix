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
  cfg = config.modernage.services.avahi;
in
{
  options.modernage.services.avahi = with types; {
    enable = mkBoolOpt false "Whether or not to enable avahi.";
  };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      # Off deliberately: nothing on the LAN publishes a routable AAAA, so every
      # .local lookup burned ~5s waiting for an answer that never came before
      # falling back to IPv4. Link-local AAAA can't cross the 10.10.0/24 <->
      # 10.10.3/24 router hop either.
      nssmdns6 = false;
      ipv6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  };
}
