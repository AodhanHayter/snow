{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.herdr;
  configDir = "${config.home.homeDirectory}/.config/herdr";
  configToml = (pkgs.formats.toml { }).generate "herdr-config.toml" cfg.settings;
in
{
  options.modernage.cli-apps.herdr = {
    enable = mkBoolOpt false "Whether or not to install herdr.";

    package =
      mkOpt types.package inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
        "The herdr package to use.";

    settings = mkOpt (types.attrsOf types.anything) {
      onboarding = false;

      theme.name = "nord";

      keys = {
        prefix = "ctrl+a";
        switch_tab = "prefix+1..9";
        switch_workspace = "prefix+shift+1..9";

        # tmux-style bindings (prefix is the leader)
        split_vertical = "prefix+%";
        split_horizontal = "prefix+\"";
        detach = "prefix+d";

        # leader+s opens the workspace ("spaces") picker; settings moves to shift+s
        workspace_picker = "prefix+s";
        settings = "prefix+shift+s";

        # vim-style j/k move the selection in the spaces picker
        navigate_workspace_up = "k";
        navigate_workspace_down = "j";
        navigate_pane_up = "";
        navigate_pane_down = "";

        # leader+. / leader+, step to next / previous agent
        next_agent = "prefix+.";
        previous_agent = "prefix+,";
      };

      ui = {
        show_agent_labels_on_pane_borders = true;
        toast.delivery = "terminal";
      };

      experimental.pane_history = false;
    } "herdr config.toml contents, rendered declaratively.";
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # herdr's settings UI writes config.toml back, so install a writable copy
    # rather than a read-only store symlink. Nix stays the source of truth.
    home.activation.herdrConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${configDir}"
      configTarget="${configDir}/config.toml"
      if [ -L "$configTarget" ] && [[ "$(readlink "$configTarget")" == /nix/store/* ]]; then
        run rm -f "$configTarget"
      fi
      run install -m 0644 ${configToml} "$configTarget"
    '';
  };
}
