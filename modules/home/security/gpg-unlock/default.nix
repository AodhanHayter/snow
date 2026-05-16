{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.security.gpg-unlock;
  unlockScript = pkgs.writeShellScript "gpg-unlock" ''
    set -euo pipefail
    pw_file="${config.sops.secrets."gpg/passphrase".path}"
    if [ ! -r "$pw_file" ]; then
      echo "gpg-unlock: passphrase file unreadable: $pw_file" >&2
      exit 1
    fi
    pw="$(cat "$pw_file")"
    # strip a single trailing newline if sops added one
    pw="''${pw%$'\n'}"
    ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
    ${concatMapStringsSep "\n" (kg: ''
      printf '%s' "$pw" | \
        ${pkgs.gnupg}/libexec/gpg-preset-passphrase --preset ${kg}
    '') cfg.keygrips}
    unset pw
  '';
in
{
  options.modernage.security.gpg-unlock = with types; {
    enable = mkBoolOpt false "Preset GPG keygrip passphrases into gpg-agent at session start using a sops-stored passphrase.";
    keygrips =
      mkOpt (listOf str) [ ]
        "GPG keygrips (uppercase hex) whose passphrase should be preset at session start.";
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    sops.secrets."gpg/passphrase" = { };

    systemd.user.services.gpg-unlock = {
      Unit = {
        Description = "Preset GPG passphrase into gpg-agent at session start";
        After = [
          "sops-nix.service"
          "gpg-agent.service"
        ];
        Wants = [
          "sops-nix.service"
          "gpg-agent.service"
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
