{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.fish;
in
{
  options.modernage.cli-apps.fish = {
    enable = mkBoolOpt false "Whether or not to enable fish shell configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.nix-your-shell ];

    programs.fish = {
      enable = true;

      interactiveShellInit = ''
        set -g fish_greeting
        fish_vi_key_bindings
        set -g fish_autocd 1
        set -gx PATH $HOME/.local/bin $PATH
        set -gx ERL_AFLAGS "-kernel shell_history enabled"

        # nix shell integration — stay in fish inside nix-shell/nix develop
        nix-your-shell fish | source

        # syntax highlighting colors (matches prezto theme)
        set fish_color_command blue
        set fish_color_keyword blue
        set fish_color_quote yellow
        set fish_color_redirection cyan
        set fish_color_end green
        set fish_color_error red
        set fish_color_param cyan
        set fish_color_operator green
        set fish_color_autosuggestion brblack
        set fish_color_valid_path --underline
      '';

      shellAbbrs = {
        ccd = "claude --dangerously-skip-permissions";
      };

      functions = {
        pg = ''
          if test (count $argv) -gt 0
            PGSERVICE=$argv[1] $HOME/.nix-profile/bin/pgcli
          else
            echo 'A valid service name is required for this function'
          end
        '';

        aws_login = ''
          saml2aws login --session-duration 43200 --username "ahayter@kyruus.com" --duo-mfa-option="Duo Push" --skip-prompt --force --role="arn:aws:iam::206670668379:role/kyruusone-engineer"
        '';

        aws_env = ''
          set -gx AWS_ACCESS_KEY_ID (aws configure get default.aws_access_key_id)
          set -gx AWS_SECRET_ACCESS_KEY (aws configure get default.aws_secret_access_key)
          set -gx AWS_SESSION_TOKEN (aws configure get default.aws_session_token)
          set -gx AWS_SECURITY_TOKEN (aws configure get default.aws_security_token)
        '';
      }
      // optionalAttrs pkgs.stdenv.isLinux {
        # Unlock gnome-keyring login keyring from a TTY (for SSH where gcr-prompter can't show).
        # Replaces any running daemon; reads password from stdin via `read -s`.
        # Verifies via D-Bus because `gnome-keyring-daemon --unlock` exits 0 even on wrong password.
        unlock-keyring = ''
          read -s -P "keyring password: " kpw
          echo
          if test -z "$kpw"
            echo "no password entered, aborting" >&2
            return 1
          end
          echo -n "$kpw" | gnome-keyring-daemon --replace --unlock --components=secrets >/dev/null 2>&1
          set -l rc $status
          set -e kpw
          if test $rc -ne 0
            echo "gnome-keyring-daemon exited $rc" >&2
            return $rc
          end
          # Daemon forks; give it a moment to claim the bus name and process the password.
          sleep 0.3
          set -l locked (busctl --user get-property org.freedesktop.secrets \
            /org/freedesktop/secrets/collection/login \
            org.freedesktop.Secret.Collection Locked 2>/dev/null \
            | string replace -r '^b ' "")
          switch "$locked"
            case false
              echo "keyring unlocked"
              return 0
            case true
              echo "unlock failed: keyring is still locked (wrong password?)" >&2
              return 1
            case '*'
              echo "could not verify keyring state via D-Bus (got: '$locked')" >&2
              return 2
          end
        '';
      };

      plugins = [
        {
          name = "fzf.fish";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "v10.3";
            sha256 = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
          };
        }
        {
          name = "git-abbr";
          inherit (pkgs.fishPlugins.git-abbr) src;
        }
      ];
    };
  };
}
