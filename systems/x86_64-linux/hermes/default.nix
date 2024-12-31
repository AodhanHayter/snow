{ pkgs
, config
, lib
, channel
, ...
}:
with lib;
with lib.modernage; {
  imports = [ ./disk-config.nix ];

  networking.hostName = "hermes";

  modernage = {
    prototype = {
      lab-node = enabled;
    };

    services.k3s = {
      enable = true;
      role = "agent";
      token = "K10d4c6e3a007386169463cb07da0492f1454b9ec49aa8f8d8ea8a47f6e338fe871::server:28f7b49327c3ba997d51673418c5fb15";
    };

    services.gluster = {
      enable = true;
      nodeAddress = "hermes.local";
      peerNodes = [ "atlas.local" "apollo.local" ];
      volumeName = "k3s-vol";
      brickPath = "/data/glusterfs/brick1";
      replicaCount = 3;
    };
  };


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
