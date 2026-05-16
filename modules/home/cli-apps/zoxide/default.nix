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
      # Manage fish integration manually so init runs last (after fish/devenv/nix-your-shell).
      enableFishIntegration = false;
    };

    programs.fish.interactiveShellInit = mkIf config.modernage.cli-apps.fish.enable (mkAfter ''
      # Scrub leaked __zoxide_loop guard var (fish 4.x scope quirk with `VAR=val func`).
      set -e __zoxide_loop
      ${config.programs.zoxide.package}/bin/zoxide init fish ${zoxideOpts} | source
    '');
  };
}
