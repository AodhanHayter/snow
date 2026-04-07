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
  pinentry-wrapper = pkgs.writeShellScriptBin "pinentry" ''
    # When accessed via SSH, gpg-agent passes the client's ttyname
    # but no DISPLAY/WAYLAND_DISPLAY (if updatestartuptty was called).
    # Fall back to curses when no graphical display is available for
    # this specific pinentry invocation, or when PINENTRY_USER_DATA=curses.
    if [ "$PINENTRY_USER_DATA" = "curses" ] || { [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; }; then
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
    pinentry-program ${pinentry-wrapper}/bin/pinentry
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
        pinentryPackage = pinentry-wrapper;
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
