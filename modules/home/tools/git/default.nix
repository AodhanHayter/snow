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
    programs.git = {
      enable = true;
      inherit (cfg) userName userEmail;
      aliases = {
        sync = "!sh -c 'git fetch origin \"$0\":\"$0\"'";
        prune = "fetch --prune";
        undo = "reset --soft HEAD^";
        stash-all = "stash save --include-untracked";
        glog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
        clean-remotes = "remote prune origin";
        clean-remotes-dry = "remote prune origin --dry-run";
        clean-locals = "!git branch -vv | rg 'origin/.+: gone]' | awk '{print $1}' | xargs git branch -d";
        clean-locals-dry = "!git branch -vv | rg 'origin/.+: gone]' | awk '{print $1}'";
      };
      diff-so-fancy = {
        enable = true;
      };
      lfs = enabled;
      signing = {
        key = cfg.signingKey;
        signByDefault = cfg.signByDefault;
      };
      ignores = ["aodhanlocal"];
      extraConfig = {
        pull = { rebase = true; };
        push = { autoSetupRemote = true; };
        core = { whitespace = "trailing-space,space-before-tab"; };
        rerere = { enabled = true; };
      };
    };
  };
}
