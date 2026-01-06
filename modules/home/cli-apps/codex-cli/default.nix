{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.codex-cli;
in
{
  options.modernage.cli-apps.codex-cli = {
    enable = mkBoolOpt false "Whether or not to install OpenAI Codex CLI.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ codex-cli ];
  };
}
