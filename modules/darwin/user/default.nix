{ lib
, config
, pkgs
, ...
}:
let
  inherit (lib) types mkIf mkDefault;
  inherit (lib.modernage) mkOpt;

  cfg = config.modernage.user;

  is-linux = pkgs.stdenv.isLinux;
  is-darwin = pkgs.stdenv.isDarwin;

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnEsBv5zrOZzeQSymd/WKottg28l0mav/J0m0/Q3E4X aodhan.hayter@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMTBSBlivmm4W46rP9m+qHPwumFuepcjP9Jl6iYhcZS5 aodhan.hayter@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5Gq86apfFdEbHIvTK+n1f7txgRYDakWfTARSzct0om aodhan.hayter@gmail.com"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL2eiUV5XxJPf6LaHmwGKNHnUyItlp4y1kt64kVlcsvzlU62Pe9GAsduW1Iv1K/gGCwRPj5wK5jf6derQqbydYM= #ssh.id - @aodhanhayter"
  ];
in
{
  options.modernage.user = {
    name = mkOpt types.str "aodhan" "The user account.";

    fullName = mkOpt types.str "Aodhan Hayter" "The full name of the user.";
    email = mkOpt types.str "aodhan.hayter@gmail.com" "The email of the user.";

    uid = mkOpt (types.nullOr types.int) 501 "The uid for the user account.";
  };

  config = {
    system.primaryUser = config.modernage.user.name;
    programs.fish.enable = true;
    environment.shells = [ pkgs.fish ];

    users.knownUsers = [ cfg.name ];

    users.users.${cfg.name} = {
      # NOTE: Setting the uid here is required for another
      # module to evaluate successfully since it reads
      # `users.users.${modernage.user.name}.uid`.
      uid = mkIf (cfg.uid != null) cfg.uid;
      shell = pkgs.fish;
    };

    snowfallorg.users.${config.modernage.user.name}.home.config = {
      home = {
        file = {
          ".profile".text = ''
            # The default file limit is far too low and throws an error when rebuilding the system.
            # See the original with: ulimit -Sa
            ulimit -n 10240
          '';
          ".ssh/authorized_keys".text = lib.concatStringsSep "\n" authorizedKeys + "\n";
        };
      };
    };
  };
}
