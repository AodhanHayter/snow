{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.podman;
in
{
  options.modernage.tools.podman = with types; {
    enable = mkBoolOpt false "Whether or not to enable podman configuration.";
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;

      ## Alias `docker` to podman and expose a docker-compatible socket.
      dockerCompat = true;
      dockerSocket.enable = true;

      ## Required for containers to resolve each other by name on the
      ## default network.
      defaultNetwork.settings.dns_enabled = true;
    };

    ## Use podman as the backend for `virtualisation.oci-containers.containers`.
    virtualisation.oci-containers.backend = "podman";

    ## Grants access to the docker-compatible socket.
    modernage.user.extraGroups = [ "podman" ];

    environment.systemPackages = with pkgs; [
      docker-compose
      docker-credential-helpers
    ];
  };
}
