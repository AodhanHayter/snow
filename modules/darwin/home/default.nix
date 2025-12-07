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
  cfg = config.modernage.home;
in
{
  options.modernage.home = with types; {
    file = mkOpt attrs { }
      "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile = mkOpt attrs { }
      "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
    homeConfig = mkOpt attrs { } "Final config for home-manager.";
  };

  config = {
    modernage.home.extraOptions = {
      home.stateVersion = mkDefault "22.05";
      home.file = mkAliasDefinitions options.modernage.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.modernage.home.configFile;
    };

    snowfallorg.users.${config.modernage.user.name}.home.config = mkAliasDefinitions options.modernage.home.extraOptions;

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      backupFileExtension = "bak";
    };
  };
}
