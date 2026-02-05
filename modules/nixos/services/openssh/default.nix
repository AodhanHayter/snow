{ options
, config
, lib
, pkgs
, format ? ""
, ...
}:
with lib;
with lib.modernage; let
  cfg = config.modernage.services.openssh;
  default-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnEsBv5zrOZzeQSymd/WKottg28l0mav/J0m0/Q3E4X aodhan.hayter@gmail.com";
  desktop-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMTBSBlivmm4W46rP9m+qHPwumFuepcjP9Jl6iYhcZS5 aodhan.hayter@gmail.com";
  macmini-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5Gq86apfFdEbHIvTK+n1f7txgRYDakWfTARSzct0om aodhan.hayter@gmail.com";
  sshid-key = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL2eiUV5XxJPf6LaHmwGKNHnUyItlp4y1kt64kVlcsvzlU62Pe9GAsduW1Iv1K/gGCwRPj5wK5jf6derQqbydYM= #ssh.id - @aodhanhayter";
in
{
  options.modernage.services.openssh = with types;
    {
      enable =
        mkBoolOpt false "Whether or not to enable openssh configuration.";
      authorizedKeys = mkOpt (listOf str) [ default-key desktop-key macmini-key sshid-key ] "The public keys to apply.";
      port = mkOpt port 2222 "The port to listen on (in addition to 22).";
    };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;

      settings = {
        PermitRootLogin =
          if format == "install-iso"
          then "yes"
          else "no";
        PasswordAuthentication = false;
      };

      ports = [ 22 cfg.port ];
    };

    modernage.user.extraOptions.openssh.authorizedKeys.keys = cfg.authorizedKeys;
    users.users.root.openssh.authorizedKeys.keys = if format == "install-iso" then cfg.authorizedKeys else [ ];
  };
}
