{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.gh;
in
{
  options.modernage.cli-apps.gh = {
    enable = mkBoolOpt false "Whether or not to install and configure gh.";
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "https";
        prompt = "enabled";
        editor = "nvim";
        pager = "less";
      };
    };
  };
}
