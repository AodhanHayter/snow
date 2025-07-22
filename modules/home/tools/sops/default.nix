{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.sops;
  user = config.modernage.user;
  home-directory =
    if user.name == null then
      null
    else if pkgs.stdenv.isDarwin then
      "/Users/${user.name}"
    else
      "/home/${user.name}";
in
{
  options.modernage.tools.sops = with types; {
    enable = mkBoolOpt false "Whether or not to enable sops.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sops
    ];
    sops = {
      defaultSopsFile = snowfall.fs.get-file "secrets/secrets.yaml";
      defaultSopsFormat = "yaml";
      age.keyFile = "${home-directory}/.config/sops/age/keys.txt";
      secrets = {
        "github/token" = { };
        "llm/gemini_api_key" = { };
        "llm/gemini_api_key_kyruus" = { };
        "llm/anthropic_api_key" = { };
        "llm/anthropic_api_key_kyruus" = { };
        "llm/groq_api_key" = { };
        "search/brave_api_key" = { };
      };
    };

  };
}
