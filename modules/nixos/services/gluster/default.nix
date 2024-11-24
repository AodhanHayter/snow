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
      useRpcbind = true;
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

      extraCommands = ''
        # Allow GlusterFS traffic
        iptables -A INPUT -p tcp --dport 24007:24008 -j ACCEPT
        iptables -A INPUT -p tcp --dport 49152:49252 -j ACCEPT
        # Allow traffic between GlusterFS nodes
        iptables -A INPUT -p tcp -s 192.168.1.0/24 -j ACCEPT  # Adjust subnet to match your network
      '';
    };

    # systemd.services.gluster-setup = {
    #   description = "Setup GlusterFS peer and volume configuration";
    #   requires = [ "network-online.target" "glusterd.service" ];
    #   after = [ "network-online.target" "glusterd.service" ];
    #   path = [ pkgs.glusterfs pkgs.gawk ];
    #
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     StandardOutput = "journal";
    #     StandardError = "journal";
    #   };
    #
    #   script =
    #     let
    #       primaryConfig =
    #         if cfg.isPrimary then ''
    #           echo "Running as primary node ${cfg.nodeAddress}"
    #           echo "Will attempt to peer with: ${builtins.concatStringsSep ", " cfg.peerNodes}"
    #
    #           # Ensure glusterd is running and settled
    #           echo "Waiting for glusterd to be fully operational..."
    #           sleep 15
    #
    #           # Function to check peer status
    #           check_peer_status() {
    #             local peer=$1
    #             # Get the peer status and parse it more carefully
    #             peer_state=$(gluster peer status | grep -A2 "Hostname: $peer" | grep "State:" | awk '{print $2" "$3" "$4}')
    #             if [ "$peer_state" = "Peer in Cluster" ]; then
    #               echo "Peer $peer is in state: $peer_state"
    #               return 0
    #             else
    #               echo "Peer $peer is in state: $peer_state"
    #               return 1
    #             fi
    #           }
    #
    #           # Function to show full peer status for debugging
    #           show_peer_status() {
    #             echo "Current peer status:"
    #             gluster peer status
    #             echo "------------------------"
    #           }
    #
    #           # Probe and verify each peer
    #           ${builtins.concatStringsSep "\n" (map (node: ''
    #             echo "Attempting to probe peer ${node}..."
    #
    #             # Try probing multiple times if needed
    #             max_attempts=5
    #             attempt=1
    #             while [ $attempt -le $max_attempts ]; do
    #               echo "Probe attempt $attempt for ${node}"
    #               if gluster peer probe ${node}; then
    #                 echo "Probe command successful for ${node}, checking status..."
    #
    #                 # Wait for peer to connect
    #                 connected=0
    #                 for i in $(seq 1 12); do
    #                   if check_peer_status "${node}"; then
    #                     echo "Peer ${node} is now in Connected state"
    #                     connected=1
    #                     break
    #                   fi
    #                   echo "Waiting for peer ${node} to connect... attempt $i/12"
    #                   show_peer_status
    #                   sleep 5
    #                 done
    #
    #                 if [ $connected -eq 1 ]; then
    #                   break
    #                 fi
    #               fi
    #
    #               echo "Attempt $attempt failed, retrying..."
    #               show_peer_status
    #               attempt=$((attempt + 1))
    #               sleep 5
    #             done
    #
    #             if ! check_peer_status "${node}"; then
    #               echo "Failed to establish peer connection with ${node} after $max_attempts attempts"
    #               show_peer_status
    #               exit 1
    #             fi
    #           '') cfg.peerNodes)}
    #
    #           echo "All peers connected. Current peer status:"
    #           show_peer_status
    #
    #           # Additional wait for cluster to settle
    #           echo "Waiting for cluster to settle..."
    #           sleep 10
    #
    #           # Check if volume exists
    #           echo "Checking for existing volume ${cfg.volumeName}..."
    #           if ! gluster volume info ${cfg.volumeName}; then
    #             echo "Volume doesn't exist, creating..."
    #             echo "Using brick list: ${brickList}"
    #
    #             # Double-check all peers before volume creation
    #             all_peers_connected=true
    #             for peer in ${builtins.concatStringsSep " " cfg.peerNodes}; do
    #               if ! check_peer_status "$peer"; then
    #                 echo "Peer $peer not in correct state before volume creation!"
    #                 all_peers_connected=false
    #               fi
    #             done
    #
    #             if [ "$all_peers_connected" = false ]; then
    #               echo "Not all peers are connected. Current status:"
    #               show_peer_status
    #               exit 1
    #             fi
    #
    #             if gluster volume create ${cfg.volumeName} \
    #               replica ${toString cfg.replicaCount} \
    #               ${brickList} force; then
    #               echo "Volume created successfully"
    #             else
    #               echo "Volume creation failed"
    #               show_peer_status
    #               echo "Brick directory contents:"
    #               ls -la ${cfg.brickPath}/${cfg.volumeName}
    #               exit 1
    #             fi
    #
    #             echo "Starting volume ${cfg.volumeName}..."
    #             if gluster volume start ${cfg.volumeName}; then
    #               echo "Volume started successfully"
    #             else
    #               echo "Volume start failed"
    #               exit 1
    #             fi
    #
    #             echo "Configuring volume options..."
    #             gluster volume set ${cfg.volumeName} performance.cache-size 256MB
    #             gluster volume set ${cfg.volumeName} performance.io-thread-count 32
    #             gluster volume set ${cfg.volumeName} network.ping-timeout 10
    #             gluster volume set ${cfg.volumeName} auth.allow '*'
    #             gluster volume set ${cfg.volumeName} cluster.heal-timeout 5
    #             gluster volume set ${cfg.volumeName} performance.write-behind-window-size 8MB
    #
    #             echo "Volume options configured. Current volume info:"
    #             gluster volume info ${cfg.volumeName}
    #           else
    #             echo "Volume ${cfg.volumeName} already exists"
    #           fi
    #         '' else ''
    #           echo "Running as secondary node ${cfg.nodeAddress}"
    #           echo "Waiting for primary node to initialize cluster..."
    #         '';
    #     in
    #     ''
    #       # Print initial configuration
    #       echo "Starting GlusterFS setup for node ${cfg.nodeAddress}"
    #       echo "Using brick path: ${cfg.brickPath}/${cfg.volumeName}"
    #
    #       # Check if glusterd is running
    #       if ! systemctl is-active glusterd; then
    #         echo "glusterd is not running!"
    #         exit 1
    #       fi
    #
    #       # Create brick directory
    #       echo "Creating brick directory..."
    #       if mkdir -p ${cfg.brickPath}/${cfg.volumeName}; then
    #         echo "Brick directory created successfully"
    #         chmod 755 ${cfg.brickPath}/${cfg.volumeName}
    #       else
    #         echo "Failed to create brick directory"
    #         exit 1
    #       fi
    #
    #       # Check brick directory permissions
    #       echo "Brick directory permissions:"
    #       ls -la ${cfg.brickPath}/${cfg.volumeName}
    #
    #       ${primaryConfig}
    #
    #       echo "GlusterFS setup completed"
    #     '';
    # };
  };
}
