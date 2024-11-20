{ options
, config
, lib
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.services.kubernetes;
in
{
  options.modernage.services.kubernetes = with types; {
    enable = mkBoolOpt false "Whether or not to enable kubernetes configuration";
    role = mkOpt (enum [ "master" "node" ]) "node" "The role this kubernetes machine should take";
    masterAddress = mkOpt (nullOr str) null "The clusterwide available network address or hostname for the kubernetes master server.";
    clusterCidr = mkOpt (nullOr str) null "CIDR range for pods in cluster";
  };

  config = mkIf cfg.enable {
    services.kubernetes = {
      roles = [ cfg.role ];
      easyCerts = true;
      masterAddress =
        if cfg.role == "master"
        then cfg.masterAddress else throw "If role is set to 'master' then a masterAddress must be configured.";
      clusterCidr = cfg.clusterCidr;
    };
  };
}
