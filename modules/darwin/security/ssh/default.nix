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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ openssh ];
    services.openssh.enable = cfg.server;
  };
}
