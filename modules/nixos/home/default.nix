{ options
, config
, pkgs
, lib
, inputs
, ...
}:

with lib;
with lib.modernage;
let cfg = config.modernage.home;
in
{
  # imports = with inputs; [
  #   home-manager.nixosModules.home-manager
  # ];

  options.modernage.home = with types; {
    file = mkOpt attrs { }
      (mdDoc "A set of files to be managed by home-manager's `home.file`.");
    configFile = mkOpt attrs { }
      (mdDoc "A set of files to be managed by home-manager's `xdg.configFile`.");
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
  };

  config = {
    modernage.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions options.modernage.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.modernage.home.configFile;
    };

    home-manager = {
      backupFileExtension = "bak";
      useUserPackages = true;
      useGlobalPkgs = true;

      users.${config.modernage.user.name} =
        mkAliasDefinitions options.modernage.home.extraOptions;
    };
  };
}
