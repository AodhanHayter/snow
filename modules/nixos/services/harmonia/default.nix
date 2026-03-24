{
  config,
  lib,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.services.harmonia;
in
{
  options.modernage.services.harmonia = with types; {
    enable = mkBoolOpt false "Whether or not to enable the harmonia binary cache.";
    port = mkOpt port 5000 "The port to listen on.";
  };

  config = mkIf cfg.enable {
    sops.secrets."harmonia/signing-key" = { };

    services.harmonia = {
      enable = true;
      signKeyPaths = [ config.sops.secrets."harmonia/signing-key".path ];
      settings.bind = "[::]:${toString cfg.port}";
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
