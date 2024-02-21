{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage; let
  username = config.modernage.user.name;
  cfg = config.modernage.suites.desktop;
  pvpn = pkgs.protonvpn-cli_2;
in
{
  options.modernage.services.protonvpn = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable proton-vpn.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [{ assertion = username != null; message = "modernage.user.name must be set"; }];

      environment.systemPackages = [ pvpn ];
      systemd.services.protonvpn = {
        description = "Autoconnect ProtonVPN";
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.which pkgs.iproute2 pkgs.sysctl pkgs.procps];
        environment = {
          PVPN_WAIT = "300";
          PVPN_DEBUG = "1";
        };
        serviceConfig = {
          Type = "forking";
          ExecStart = "${pvpn}/bin/protonvpn connect -f";
        };
      };
    }
  ]);
}
