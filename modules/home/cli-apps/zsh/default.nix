{ lib
, config
, pkgs
, ...
}:
with lib;
with lib.modernage;
let cfg = config.modernage.cli-apps.zsh;
in
{
  options.modernage.cli-apps.zsh = {
    enable = mkBoolOpt false "Whether or not to enable ZSH configuration";
  };

  config = mkIf cfg.enable
    {
      programs = {
        zsh = {
          enable = true;
          enableCompletion = true;
          syntaxHighlighting.enable = true;

          initExtra = ''
            # Fix an issue with tmux.
            export KEYTIMEOUT=1

            function pg() {
              if [ $1 ]; then
                PGSERVICE=$1 $HOME/.nix-profile/bin/pgcli
              else
                echo 'A valid service name is required for this function'
              fi
            }

            function aws_login() {
              saml2aws login --session-duration 43200 --username "ahayter@kyruus.com" --duo-mfa-option="Duo Push" --skip-prompt --force --role="arn:aws:iam::206670668379:role/kyruusone-engineer"
            }

            function aws_env() {
              export AWS_ACCESS_KEY_ID=$(aws configure get default.aws_access_key_id)
              export AWS_SECRET_ACCESS_KEY=$(aws configure get default.aws_secret_access_key)
              export AWS_SESSION_TOKEN=$(aws configure get default.aws_session_token)
              export AWS_SECURITY_TOKEN=$(aws configure get default.aws_security_token)
            }
          '';

          prezto = {
            enable = true;

            caseSensitive = false;

            editor = {
              dotExpansion = true;
              keymap = "vi";
            };

            syntaxHighlighting = {
              styles = {
                alias = "fg=blue";
                builtin = "fg=blue";
                command = "fg=blue";
                function = "fg=blue";
                precommand = "fg=cyan";
                commandseparator = "fg=green";
              };
            };

            pmodules = [
              "environment"
              "terminal"
              "editor"
              "history"
              "directory"
              "spectrum"
              "utility"
              "completion"
              "syntax-highlighting"
              "history-substring-search"
              "git"
            ];
          };

          plugins = [
            {
              name = "zsh-nix-shell";
              file = "nix-shell.plugin.zsh";
              src = pkgs.fetchFromGitHub {
                owner = "chisui";
                repo = "zsh-nix-shell";
                rev = "v0.4.0";
                sha256 = "037wz9fqmx0ngcwl9az55fgkipb745rymznxnssr3rx9irb6apzg";
              };
            }
            {
              name = "zsh-async";
              file = "async.zsh";
              src = pkgs.fetchFromGitHub {
                owner = "mafredri";
                repo = "zsh-async";
                rev = "v1.8.5";
                sha256 = "sha256-mpXT3Hoz0ptVOgFMBCuJa0EPkqP4wZLvr81+1uHDlCc=";
              };
            }
            {
              name = "pure";
              file = "pure.zsh";
              src = pkgs.fetchFromGitHub {
                owner = "sindresorhus";
                repo = "pure";
                rev = "v1.20.1";
                sha256 = "sha256-iuLi0o++e0PqK81AKWfIbCV0CTIxq2Oki6U2oEYsr68=";
              };
            }
          ];
        };
      };
    };
}
