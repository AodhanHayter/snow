{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.modernage;
let cfg = config.modernage.security.yubikey-manager;
in {
  options.modernage.security.yubikey-manager = with types; {
    enable = mkBoolOpt false "Whether to enable the YubiKey manager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.yubikey-manager
    ];
  };
}
