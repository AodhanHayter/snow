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
    sops = {
      defaultSopsFile = snowfall.fs.get-file "secrets/secrets.yaml";
      defaultSopsFormat = "yaml";
      age.keyFile = "${home-directory}/.config/sops/age/keys.txt";
      secrets = {
        "k3s/token" = { };
      };
    };

  };
}
