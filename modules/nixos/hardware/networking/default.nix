{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.hardware.networking;
in
{
  options.modernage.hardware.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support.";
    randomMacAddr = mkBoolOpt true "Wheter or not to randomize network card mac address for privacy.";
    hosts = mkOpt attrs { } (mdDoc "An attribute set to merge with `networking.hosts`");
  };

  config = mkIf cfg.enable {
    modernage.user.extraGroups = [ "networkmanager" ];

    networking = {
      hosts = {
        "127.0.0.1" = [ "local.test" ] ++ (cfg.hosts."127.0.0.1" or [ ]);
      } // cfg.hosts;

      networkmanager = {
        enable = true;
        dhcp = "internal";
        wifi = {
          scanRandMacAddress = cfg.randomMacAddr;
        };
      };
    };


    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
