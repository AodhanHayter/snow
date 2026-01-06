{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.services.k3s;
in
{
  options.modernage.services.k3s = with types; {
    enable = mkBoolOpt false "Whether or not to enable k3s configuration";
    role = mkOpt (enum [
      "server"
      "agent"
    ]) "server" "The role this k3s machine should take";
    clusterInit = mkBoolOpt false "Initialize HA cluster using an embedded etcd datastore";
    tokenFile =
      mkOpt (nullOr path) null
        "Path to a file containing the k3s cluster token. Required for agents and recommended for servers.";
  };

  config = mkIf cfg.enable {

    networking.firewall = {
      allowedTCPPorts = [
        6443 # k3s; required so that pods can reach the API server
        2379 # k3s; etcd clients
        2380 # k3s; etcd peers
      ];

      allowedUDPPorts = [
        8472 # k3s, flannel: required if using multi-node for inter-node networking
      ];
    };

    services.k3s = {
      enable = true;
      role = cfg.role;
      clusterInit = cfg.clusterInit;
      serverAddr = if cfg.role == "agent" then "https://atlas.local:6443" else "";
      tokenFile = cfg.tokenFile;
    };

    # support for longhorn storage system
    services.openiscsi = {
      enable = true;
      name = "iqn.2020-08.org.linux-iscsi.initiatorhost:nixos";
    };
  };
}
