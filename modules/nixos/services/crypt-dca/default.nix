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
  cfg = config.modernage.services.crypt-dca;
  dataDir = "/srv/crypt-dca";
in
{
  options.modernage.services.crypt-dca = with types; {
    enable = mkBoolOpt false "Whether or not to enable the crypt DCA bot.";
    image = mkOpt str "docker.io/library/processes:latest" "Container image name.";
    dryRun = mkBoolOpt true "Run in dry-run mode (no real trades).";
  };

  config = mkIf cfg.enable {
    virtualisation.podman.enable = true;

    # Ensure host directories exist
    systemd.tmpfiles.rules = [
      "d ${dataDir}/data 0750 root root -"
      "d ${dataDir}/logs 0750 root root -"
    ];

    # Declare sops secrets
    sops.secrets."coinbase/api_key" = { };
    sops.secrets."coinbase/api_secret" = { };

    # Template an env file from sops secrets
    sops.templates."crypt-dca.env" = {
      content = ''
        COINBASE_API_KEY=${config.sops.placeholder."coinbase/api_key"}
        COINBASE_API_SECRET=${config.sops.placeholder."coinbase/api_secret"}
        DRY_RUN=${if cfg.dryRun then "true" else "false"}
        TZ=America/Denver
      '';
    };

    # Podman container managed by systemd
    virtualisation.oci-containers = {
      backend = "podman";
      containers.crypt-dca = {
        image = cfg.image;
        environmentFiles = [
          config.sops.templates."crypt-dca.env".path
        ];
        volumes = [
          "${dataDir}/data:/app/data"
          "${dataDir}/logs:/app/logs"
        ];
      };
    };
  };
}
