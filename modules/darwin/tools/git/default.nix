{ lib, config, pkgs, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.tools.git;
  user = config.modernage.user;
in
{
  options.modernage.tools.git = {
    enable = mkBoolOpt false "Whether or not to install and configure git.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with";
    signingKey = mkOpt types.str "3FBACD0B82D05567FC1BB765FD58CC579E91D1C5" "The key ID to sign commits with.";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ git ];

    modernage.home.extraOptions = {
      programs.git = {
        enable = true;
        inherit (cfg) userName userEmail;
        lfs = enabled;
        signing = {
          key = cfg.signingKey;
          signByDefault = cfg.signByDefault;
        };
        extraConfig = {
          pull = { rebase = true; };
          push = { autoSetupRemote = true; };
          core = { whitespace = "trailing-space,space-before-tab"; };
        };
      };

    };
  };
}
