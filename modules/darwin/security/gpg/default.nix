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
    if [ "$PINENTRY_USER_DATA" = "curses" ]; then
      exec ${pkgs.pinentry-curses}/bin/pinentry-curses "$@"
    else
      exec ${pkgs.pinentry_mac}/bin/pinentry-mac "$@"
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
    environment.systemPackages = with pkgs; [ gnupg paperkey pinentry_mac pinentry-curses ];

    programs = {
      gnupg.agent = {
        enable = true;
      };
    };

    modernage = {
      home.file = {
        ".gnupg/.keep".text = "";
        ".gnupg/gpg.conf".text = gpgConf;
        ".gnupg/gpg-agent.conf".text = gpgAgentConf;
      };

      home.extraOptions.programs.bash.initExtra = ''
        export GPG_TTY=$(tty)
        if [ -n "$SSH_CONNECTION" ]; then
          export PINENTRY_USER_DATA=curses
        fi
      '';

      home.extraOptions.programs.fish.interactiveShellInit = ''
        set -gx GPG_TTY (tty)
        if set -q SSH_CONNECTION
          set -gx PINENTRY_USER_DATA curses
        end
      '';

      home.extraOptions.programs.zsh.initExtra = ''
        export GPG_TTY=$(tty)
        if [ -n "$SSH_CONNECTION" ]; then
          export PINENTRY_USER_DATA=curses
        fi
      '';
    };
  };
}
