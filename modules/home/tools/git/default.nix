{
  lib,
  config,
  pkgs,
  ...
}:
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
    signingKey =
      mkOpt types.str "3FBACD0B82D05567FC1BB765FD58CC579E91D1C5"
        "The key ID to sign commits with.";
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
      ignores = [ "aodhanlocal" ];
      extraConfig = {
        branch = {
          # Sort branches by the most recent commit date
          sort = "-committerdate";
        };
        commit = {
          verbose = true;
        };
        column = {
          # represent branch names in column formate so we can see more of them
          ui = "auto";
        };
        core = {
          fsmonitor = true;
          untrackedCache = true;
          whitespace = "trailing-space,space-before-tab";
        };
        diff = {
          # Use an improved diff algorithm
          algorithm = "histogram";
          # show code movement in different colors
          colorMoved = "plain";
          # replace diff headers output with where the diff is coming from
          mnemonicPrefix = true;
          # detect if a file has been renamed
          renames = true;
        };
        fetch = {
          # automatically prune
          prune = true;
          pruneTags = true;
          all = true;
        };
        help = {
          autocorrect = "prompt";
        };
        merge = {
          conflictStyle = "zdiff3";
        };
        pull = {
          rebase = true;
        };
        push = {
          # if remote doesn't exist automatically create and push to it
          autoSetupRemote = true;
          # push all tags that are not on the remote
          followTags = true;
        };
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        tag = {
          # sort version numbers as a series of integers
          sort = "version:refname";
        };
      };
    };
  };
}
