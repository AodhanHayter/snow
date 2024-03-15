{ options
, config
, lib
, pkgs
, ...
}:

with lib;
with lib.modernage;
let cfg = config.modernage.tools.docker;
in
{
  options.modernage.tools.docker = with types; {
    enable = mkBoolOpt false "Wheter or not to enable docker configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
      docker-credential-helpers
      docker-buildx
      colima
    ];
  };
}
