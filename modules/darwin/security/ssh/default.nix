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
    enable = mkBoolOpt false "Whether or not to install openssh"; # macOS now ships with FIDO2/yubikey support; Nix openssh causes firewall issues
    server = mkBoolOpt false "Whether to enable Remote Login (SSH server).";
    authorizedKeys = mkOpt (listOf str) [ ] "Public keys to authorize for the primary user.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ openssh ];
    })
    (mkIf cfg.server {
      services.openssh.enable = true;
    })
    (mkIf (cfg.authorizedKeys != [ ]) {
      users.users.${config.modernage.user.name}.openssh.authorizedKeys.keys = cfg.authorizedKeys;
    })
  ];
}
