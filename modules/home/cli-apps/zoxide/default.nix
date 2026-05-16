{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.zoxide;
  zoxideOpts = concatStringsSep " " config.programs.zoxide.options;
in
{
  options.modernage.cli-apps.zoxide = {
    enable = mkBoolOpt false "Whether or not to install and configure zoxide.";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      # Manage fish integration manually so init runs last (after fish/devenv/nix-your-shell).
      enableFishIntegration = false;
      options = [
        "--cmd"
        "cd"
      ];
    };

    programs.fish.interactiveShellInit = mkIf config.modernage.cli-apps.fish.enable (mkAfter ''
      ${config.programs.zoxide.package}/bin/zoxide init fish ${zoxideOpts} | source
    '');
  };
}
