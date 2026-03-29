{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.security.gpg;
  pinentry-wrapper = pkgs.writeShellScript "pinentry-wrapper" ''
    if [ -n "$SSH_CONNECTION" ]; then
      exec ${pkgs.pinentry-curses}/bin/pinentry-curses "$@"
    else
      exec ${pkgs.pinentry-gnome3}/bin/pinentry-gnome3 "$@"
    fi
  '';
  gpgConf = ''
    personal-cipher-preferences AES256 AES192 AES
    personal-digest-preferences SHA512 SHA384 SHA256
    personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
    default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
    cert-digest-algo SHA512
    s2k-digest-algo SHA512
    s2k-cipher-algo AES256
    charset utf-8
    no-comments
    no-emit-version
    no-greeting
    keyid-format 0xlong
    list-options show-uid-validity
    verify-options show-uid-validity
    with-fingerprint
    require-cross-certification
    no-symkey-cache
  '';
  gpgAgentConf = ''
    default-cache-ttl 3600
    max-cache-ttl 7200
    pinentry-program ${pinentry-wrapper}
  '';
in
{
  options.modernage.security.gpg = with types; {
    enable = mkBoolOpt false "Whether or not to enable GPG";
  };

  config = mkIf cfg.enable {
    services.pcscd.enable = true;
    environment.systemPackages = with pkgs; [ paperkey pinentry-curses pinentry-gnome3 ];

    programs = {
      gnupg.agent = {
        enable = true;
        enableExtraSocket = true;
      };
    };

    modernage = {
      home.file = {
        ".gnupg/.keep".text = "";
        ".gnupg/gpg.conf".text = gpgConf;
        ".gnupg/gpg-agent.conf".text = gpgAgentConf;
      };
    };
  };
}
