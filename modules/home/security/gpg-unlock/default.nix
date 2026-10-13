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
  # SSH logins have no gui/<uid> launchd domain, so the launchd agents never run; redo their work at login.
  loginScript = pkgs.writeShellScript "gpg-unlock-login" ''
    ${pkgs.gnupg}/bin/gpg-connect-agent "keyinfo ${head cfg.keygrips}" /bye \
      | ${pkgs.gawk}/bin/awk '$7 == "1" { f = 1 } END { exit !f }' && exit 0
    [ -r "${config.sops.secrets."gpg/passphrase".path}" ] \
      || ${config.launchd.agents.sops-nix.config.Program} >/dev/null
    exec ${unlockScript}
  '';
in
{
  options.modernage.security.gpg-unlock = with types; {
    enable = mkBoolOpt false "Preset GPG keygrip passphrases into gpg-agent at session start using a sops-stored passphrase.";
    keygrips =
      mkOpt (listOf str) [ ]
        "GPG keygrips (uppercase hex) whose passphrase should be preset at session start.";
  };

  config = mkIf cfg.enable {
    sops.secrets."gpg/passphrase" = { };

    # Darwin: no unit ordering; script exits 1 until sops-nix has decrypted, launchd retries.
    launchd.agents.gpg-unlock = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [ "${unlockScript}" ];
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
      };
    };

    programs.fish.loginShellInit = mkIf pkgs.stdenv.isDarwin "${loginScript}";

    systemd.user.services.gpg-unlock = mkIf pkgs.stdenv.isLinux {
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
