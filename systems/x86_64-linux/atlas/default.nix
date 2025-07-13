{ lib
, ...
}:
with lib;
with lib.modernage; {
  imports = [ ./disk-config.nix ];

  networking.hostName = "atlas";

  modernage = {
    prototype = {
      lab-node = enabled;
    };

    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
      };

      k3s = {
        enable = true;
        role = "server";
        clusterInit = true;
      };

      gluster = {
        enable = true;
        nodeAddress = "atlas.local";
        isPrimary = true;
        peerNodes = [ "apollo.local" "hermes.local" ];
        volumeName = "k3s-vol";
        brickPath = "/data/glusterfs/brick1";
        replicaCount = 3;
      };
    };
  };


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
