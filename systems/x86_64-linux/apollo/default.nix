{ pkgs
, config
, lib
, channel
, ...
}:
with lib;
with lib.modernage; {
  imports = [ ./disk-config.nix ];

  modernage = {
    prototype = {
      lab-node = enabled;
    };

    services.k3s = {
      enable = true;
      role = "agent";
      token = "K10221a5d12ace9b9472747b382a5a2639e63119d93bd451c8442bcc8cc76f319a4::server:3ef6f6053e126f0fd340fe772b205e47";
    };

    gluster = {
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
