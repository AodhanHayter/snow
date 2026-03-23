{
  options,
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.services.crypt-dca;
  cryptPkg = inputs.crypt.packages.${system}.default;
  dataDir = "/srv/crypt-dca";
in
{
  options.modernage.services.crypt-dca = with types; {
    enable = mkBoolOpt false "Whether or not to enable the crypt DCA bot.";
    dryRun = mkBoolOpt true "Run in dry-run mode (no real trades).";
  };

  config = mkIf cfg.enable {
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

    # Bot — runs daily at 6am Denver time
    systemd.services.crypt-dca = {
      description = "ZEC DCA Trading Bot";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = dataDir;
        EnvironmentFile = config.sops.templates."crypt-dca.env".path;
        ExecStart = "${cryptPkg}/bin/crypt-bot";
      };
    };

    systemd.timers.crypt-dca = {
      description = "Daily ZEC DCA trade";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "*-*-* 06:00:00";
        Persistent = true; # catch up if missed while offline
      };
    };

    # Dashboard — long-running web service
    systemd.services.crypt-dashboard = {
      description = "ZEC DCA Dashboard";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        WorkingDirectory = dataDir;
        EnvironmentFile = config.sops.templates."crypt-dca.env".path;
        ExecStart = "${cryptPkg}/bin/crypt-dashboard";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8000 ];
  };
}
