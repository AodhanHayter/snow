{ options
, config
, pkgs
, lib
, inputs
, ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.nix;

  substituters-submodule = types.submodule ({ name, ... }: {
    options = with types; {
      key = mkOpt (nullOr str) null "The trusted public key for this substituter.";
    };
  });
in
{
  options.modernage.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt package pkgs.nixVersions.stable "Which nix package to use.";

    default-substituter = {
      url = mkOpt str "https://cache.nixos.org" "The url for the substituter.";
      key = mkOpt str "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "The trusted public key for the substituter.";
    };

    extra-substituters = mkOpt (attrsOf substituters-submodule) { } "Extra substituters to configure.";
  };

  config = mkIf cfg.enable {
    assertions = mapAttrsToList
      (name: value: {
        assertion = value.key != null;
        message = "modernage.nix.extra-substituters.${name}.key must be set";
      })
      cfg.extra-substituters;

    environment.systemPackages = with pkgs; [
      nixfmt-rfc-style
      nix-index
      nix-prefetch-git
      nix-output-monitor
    ];

    nix =
      let users = [ "root" config.modernage.user.name ];
      in
      {
        package = cfg.package;

        settings = {
          experimental-features = "nix-command flakes";
          http-connections = 50;
          warn-dirty = false;
          log-lines = 50;
          sandbox = "relaxed";
          auto-optimise-store = true;
          trusted-users = users;
          allowed-users = users;

          substituters =
            [ cfg.default-substituter.url ]
            ++
            (mapAttrsToList (name: value: name) cfg.extra-substituters);
          trusted-public-keys =
            [ cfg.default-substituter.key ]
            ++
            (mapAttrsToList (name: value: value.key) cfg.extra-substituters);

        };

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };

        # flake-utils-plus
        generateRegistryFromInputs = true;
        generateNixPathFromInputs = true;
        linkInputs = true;
      };
  };
}
