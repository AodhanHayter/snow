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
  cfg = config.modernage.security.gpg;
  gpgConf = "${inputs.gpg-base-conf}/gpg.conf";
  gpgAgentConf = ''
    enable-ssh-support
    default-cache-ttl 60
    max-cache-ttl 120
    pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
  '';
in
{
  options.modernage.security.gpg = with types; {
    enable = mkBoolOpt false "Whether or not to enable GPG";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gnupg paperkey pinentry_mac ];

    programs = {
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };

    modernage = {
      home.file = {
        ".gnupg/.keep".text = "";
        ".gnupg/gpg.conf".source = gpgConf;
        ".gnupg/gpg-agent.conf".text = gpgAgentConf;
      };
    };
  };
}
