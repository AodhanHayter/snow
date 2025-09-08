{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.awscli;
in
{
  options.modernage.cli-apps.awscli = {
    enable = mkBoolOpt false "Whether or not to install and configure awscli.";
  };

  config = mkIf cfg.enable {

    # The home-manager setup requires more involved credentials handling
    programs.awscli = {
      enable = true;
    };

    programs.zsh.initContent = ''
      function aws_env() {
        export AWS_ACCESS_KEY_ID=$(aws configure get default.aws_access_key_id)
        export AWS_SECRET_ACCESS_KEY=$(aws configure get default.aws_secret_access_key)
        export AWS_SESSION_TOKEN=$(aws configure get default.aws_session_token)
        export AWS_SECURITY_TOKEN=$(aws configure get default.aws_security_token)
      }
    '';
  };
}
