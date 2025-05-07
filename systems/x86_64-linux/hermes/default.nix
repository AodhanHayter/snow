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

    tools = {
      sops = enabled;
    };

    services.k3s = {
      enable = true;
      role = "agent";
      tokenFile = config.sops.secrets."k3s/token".path;
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
