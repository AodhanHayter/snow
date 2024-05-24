{ lib
, config
, pkgs
, osConfig ? { }
, ...
}:

let
  inherit (lib) types mkIf mkDefault mkMerge;
  inherit (lib.modernage) mkOpt;

  cfg = config.modernage.user;

  is-linux = pkgs.stdenv.isLinux;
  is-darwin = pkgs.stdenv.isDarwin;

  home-directory =
    if cfg.name == null then
      null
    else if is-darwin then
      "/Users/${cfg.name}"
    else
      "/home/${cfg.name}";
in
{
  options.modernage.user = {
    enable = mkOpt types.bool false "Whether to configure the user account.";
    name = mkOpt (types.nullOr types.str) config.snowfallorg.user.name "The user account.";

    fullName = mkOpt types.str "Aodhan Hayter" "The full name of the user.";
    email = mkOpt types.str "aodhan.hayter@gmail.com" "The email of the user.";

    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "modernage.user.name must be set";
        }
        {
          assertion = cfg.home != null;
          message = "modernage.user.home must be set";
        }
      ];

      home = {
        username = mkDefault cfg.name;
        homeDirectory = mkDefault cfg.home;
      };

      # home.activation = mkIf pkgs.stdenv.isDarwin {
      #   copyApplications =
      #     let
      #       apps = pkgs.buildEnv {
      #         name = "home-manager-applications";
      #         paths = config.home.packages;
      #         pathsToLink = "/Applications";
      #       };
      #     in
      #     lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      #       baseDir="$HOME/Applications/Home Manager Apps"
      #       if [ -d "$baseDir" ]; then
      #         rm -rf "$baseDir"
      #       fi
      #       mkdir -p "$baseDir"
      #       for appFile in ${apps}/Applications/*; do
      #         target="$baseDir/$(basename "$appFile")"
      #         $DRY_RUN_CMD cp ''${VERBOSE_ARG:+-v} -fHRL "$appFile" "$baseDir"
      #         $DRY_RUN_CMD chmod ''${VERBOSE_ARG:+-v} -R +w "$target"
      #       done
      #     '';
      # };
    }
  ]);
}
