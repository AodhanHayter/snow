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
    users.users.${cfg.name} = {
      # NOTE: Setting the uid here is required for another
      # module to evaluate successfully since it reads
      # `users.users.${modernage.user.name}.uid`.
      uid = mkIf (cfg.uid != null) cfg.uid;
    };

    snowfallorg.users.${config.modernage.user.name}.home.config = {
      home = {
        file = {
          ".profile".text = ''
            # The default file limit is far too low and throws an error when rebuilding the system.
            # See the original with: ulimit -Sa
            ulimit -n 4096
          '';
        };
      };
    };
  };
}
