{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.security.keyring-unlock;
  unlockScript = pkgs.writeShellScript "gnome-keyring-unlock" ''
    set -euo pipefail
    pw_file="${config.sops.secrets."keyring/password".path}"
    if [ ! -r "$pw_file" ]; then
      echo "password file unreadable: $pw_file" >&2
      exit 1
    fi
    pw="$(cat "$pw_file")"
    # strip a single trailing newline if sops added one
    pw="''${pw%$'\n'}"
    printf '%s' "$pw" | ${pkgs.gnome-keyring}/bin/gnome-keyring-daemon \
      --replace --unlock --components=secrets >/dev/null 2>&1 || true
    unset pw
    sleep 0.5
    locked=$(${pkgs.systemd}/bin/busctl --user get-property \
      org.freedesktop.secrets \
      /org/freedesktop/secrets/collection/login \
      org.freedesktop.Secret.Collection Locked 2>/dev/null \
      | ${pkgs.gawk}/bin/awk '{print $2}')
    if [ "$locked" != "false" ]; then
      echo "keyring unlock failed (Locked=$locked)" >&2
      exit 1
    fi
    echo "keyring unlocked"
  '';
in
{
  options.modernage.security.keyring-unlock = {
    enable = mkBoolOpt false "Unlock gnome-keyring login keyring at user session start using a sops-stored password.";
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    sops.secrets."keyring/password" = { };

    systemd.user.services.gnome-keyring-unlock = {
      Unit = {
        Description = "Unlock gnome-keyring login keyring at session start";
        After = [
          "sops-nix.service"
          "dbus.service"
        ];
        Wants = [
          "sops-nix.service"
          "dbus.service"
        ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${unlockScript}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
