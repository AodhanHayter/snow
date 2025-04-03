{
  lib,
  config,
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
  options.modernage.tools.sops = {
    enable = mkBoolOpt false "Whether or not to install and configure sops.";
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "${home-directory}/.config/sops/age/keys.txt";

      secrets = {
        hello = { };
      };
    };
  };
}
