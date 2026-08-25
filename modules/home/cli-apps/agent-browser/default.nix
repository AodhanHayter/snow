{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.agent-browser;
in
{
  options.modernage.cli-apps.agent-browser = {
    enable = mkBoolOpt false "Whether or not to install agent-browser.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.agent-browser
    ];
  };
}
