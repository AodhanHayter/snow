{
  config,
  lib,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.services.github-runners;

  mkContainer = name: instance: {
    autoStart = true;
    ephemeral = false;
    privateNetwork = true;
    hostAddress = "10.233.${toString instance.subnet}.1";
    localAddress = "10.233.${toString instance.subnet}.2";

    bindMounts."/run/secrets/gh-runner-token" = {
      hostPath = config.sops.secrets."github-runners/${name}/token".path;
      isReadOnly = true;
    };

    config =
      { pkgs, ... }:
      {
        system.stateVersion = "25.11";

        networking = {
          firewall.enable = false;
          useHostResolvConf = lib.mkForce false;
          nameservers = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          defaultGateway = "10.233.${toString instance.subnet}.1";
        };

        services.github-runners.${name} = {
          enable = true;
          url = instance.url;
          tokenFile = "/run/secrets/gh-runner-token";
          inherit name;
          extraLabels = instance.labels;
          replace = true;
          extraPackages =
            with pkgs;
            [
              git
              gh
              curl
              wget
              cacert
              coreutils
              findutils
              gnused
              gnugrep
              gawk
              gnutar
              gzip
              unzip
              xz
              inetutils
              jq
              which
              file
              openssh
            ]
            ++ instance.extraPackages;
        };
      };
  };
in
{
  options.modernage.services.github-runners = with types; {
    enable = mkBoolOpt false "Whether or not to enable self-hosted GitHub Actions runners.";

    externalInterface = mkOpt str "enp5s0" "Host WAN interface used for NAT egress.";

    instances = mkOption {
      description = "Runner instances. Each becomes its own nixos-container.";
      default = { };
      type = attrsOf (submodule {
        options = {
          url = mkOpt types.str "" "Repo, org, or enterprise URL to register against.";
          subnet = mkOpt types.int 1 "Third octet of 10.233.X.0/24 — must be unique per instance.";
          labels = mkOpt (types.listOf types.str) [
            "self-hosted"
            "nixos"
          ] "Extra labels applied to the runner.";
          extraPackages = mkOpt (types.listOf types.package) [ ] "Packages added to the runner PATH.";
        };
      });
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = mapAttrs' (n: _: nameValuePair "github-runners/${n}/token" { }) cfg.instances;

    containers = mapAttrs' (n: i: nameValuePair "gh-runner-${n}" (mkContainer n i)) cfg.instances;

    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = cfg.externalInterface;
    };
  };
}
