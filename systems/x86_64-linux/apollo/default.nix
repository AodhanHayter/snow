{ pkgs
, config
, lib
, channel
, ...
}:
with lib;
with lib.modernage; {
  imports = [ ./disk-config.nix ];

  networking.hostName = "apollo";

  modernage = {
    prototype = {
      lab-node = enabled;
    };

    services.k3s = {
      enable = true;
      role = "agent";
      token = "K107c82aa11fd40bc86f6bf54c74604d2e5362219fc06fdf8cd6e021ae1eb27b087::server:50d968aeb9ad138010935aa1663cc212";
    };

    services.gluster = {
      enable = true;
      nodeAddress = "apollo.local";
      peerNodes = [ "atlas.local" "hermes.local" ];
      volumeName = "k3s-vol";
      brickPath = "/data/glusterfs/brick1";
      replicaCount = 3;
    };
  };


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
