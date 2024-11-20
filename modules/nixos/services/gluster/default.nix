{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.services.gluster;
  allNodes = [ cfg.nodeAddress ] ++ cfg.peerNodes;
  brickList = builtins.concatStringsSep " "
    (map (node: "${node}:${cfg.brickPath}/${cfg.volumeName}") allNodes);
in
{
  options.modernage.services.gluster = with types; {
    enable = mkBoolOpt false "Whether or not to enable k3s configuration";
    nodeAddress = mkOpt str "" "The nodes hostname or IP.";
    isPrimary = mkBoolOpt false "Is this node a primary.";
    peerNodes = mkOpt (listOf str) [ ] "List of peer node addresses, hostnames or IPs.";
    volumeName = mkOpt str "" "Name to give the gluster volume.";
    brickPath = mkOpt str "" "Path to configure gluster brick location";
    replicaCount = mkOpt int 1 "Number of replicas";
  };

  config = mkIf cfg.enable {
    services.glusterfs = {
      enable = true;
      enableClient = true;
      enableServer = true;
    };

    networking.firewall = {
      allowedTCPPorts = [
        24007 # Gluster Daemon
        24008 # Gluster Management
        38465 # Gluster NFS
        38466 # Gluster NFS
        38467 # Gluster NFS
      ];

      # Allow ports for bricks (49152:49251)
      # This range allows up to 100 bricks per node
      allowedTCPPortRanges = [
        { from = 49152; to = 49252; }
      ];
    };

    systemd.services.gluster-setup = {
      description = "Setup GlusterFS peer and volume configuration";
      requires = [ "network-online.target" "glusterd.service" ];
      after = [ "network-online.target" "glusterd.service" ];
      path = [ pkgs.glusterfs ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script =
        let
          # Only include peer probing and volume creation if this is the primary node
          primaryConfig =
            if cfg.isPrimary then ''
              # Probe peers
                ${builtins.concatStringSep "\n" (map (node: ''
                  until gluster peer probe ${node}; do
                    echo "Waiting for peer ${node} to become available..."
                    sleep 5
                  done
              '') cfg.peerNodes)}

              # Wait for peer connection to stabilize
              sleep 5

              # Create volume if it doesn't exist

              if ! gluster volume info ${cfg.volumeName}; then
                gluster volume create ${cfg.volumeName} \
                  replica ${toString cfg.replicaCount} \
                  ${brickList} force || exit 1

                gluster volume start ${cfg.volumeName}

                # Configure volume options
                gluster volume set ${cfg.volumeName} performance.cache-size 256MB
                gluster volume set ${cfg.volumeName} performance.io-thread-count 32
                gluster volume set ${cfg.volumeName} network.ping-timeout 10
                gluster volume set ${cfg.volumeName} auth.allow '*'
                gluster volume set ${cfg.volumeName} cluster.heal-timeout 5
                gluster volume set ${cfg.volumeName} performance.write-behind-window-size 8MB
              fi

            '' else "";
        in
        ''
          # Wait for glusterd to be fully up
          sleep 10

          # Create brick directory
          mkdir -p ${cfg.brickPath}/${cfg.volumeName}

          ${primaryConfig}
        '';
    };
  };
}
