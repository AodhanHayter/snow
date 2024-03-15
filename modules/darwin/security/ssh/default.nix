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
  cfg = config.modernage.security.ssh;
in
{
  options.modernage.security.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to install openssh"; # MacOS is shipped with openssh version that doesn't support yubikey
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ openssh ];
  };
}
