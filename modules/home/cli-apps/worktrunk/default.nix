{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.worktrunk;
  fishEnabled = config.modernage.cli-apps.fish.enable;
in
{
  options.modernage.cli-apps.worktrunk = {
    enable = mkBoolOpt false "Whether or not to install and configure worktrunk.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.worktrunk ];

    # Mirrors `wt config shell install fish` so `wt config show` detects the
    # integration via this file. Lazy bootstrap sources the real function from
    # the binary on first call.
    xdg.configFile = mkIf fishEnabled {
      "fish/functions/wt.fish".text = ''
        # worktrunk shell integration for fish
        # Sources full integration from binary on first use.
        # Docs: https://worktrunk.dev/config/#shell-integration
        # Check: wt config show | Uninstall: wt config shell uninstall

        function wt
            command wt config shell init fish | source
            # Check both command exit code ($pipestatus[1]) and source exit code ($pipestatus[2])
            # If source fails, the function isn't replaced and we'd infinite-loop calling ourselves
            set -l wt_status $pipestatus[1]
            set -l source_status $pipestatus[2]
            test $wt_status -eq 0; or return $wt_status
            test $source_status -eq 0; or return $source_status
            wt $argv
        end
      '';

      "fish/completions/wt.fish".text = ''
        # worktrunk completions for fish
        complete --keep-order --exclusive --command wt --arguments "(test -n \"\$WORKTRUNK_BIN\"; or set -l WORKTRUNK_BIN (type -P wt 2>/dev/null); and COMPLETE=fish \$WORKTRUNK_BIN -- (commandline --current-process --tokenize --cut-at-cursor) (commandline --current-token))"
      '';
    };
  };
}
