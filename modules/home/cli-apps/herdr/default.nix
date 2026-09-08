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

    plugins = mkOpt (types.attrsOf types.path) { } "Herdr plugins to link.";

    settings = mkOpt (types.attrsOf types.anything) {
      onboarding = false;

      theme = {
        name = "nord";
        custom = {
          sidebar_bg = "#252a34";
          active_row_bg = "#434c5e";
          selection_bg = "#5e81ac";
          accent = "#88c0d0";
          green = "#a3be8c";
          blue = "#81a1c1";
          red = "#bf616a";
          yellow = "#ebcb8b";
        };
      };

      keys = {
        prefix = "ctrl+a";
        switch_tab = "prefix+1..9";
        switch_workspace = "prefix+shift+1..9";
        goto = "prefix+t";

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

        command = [
          {
            key = "ctrl+shift+u";
            type = "plugin_action";
            command = "usagebar.open-limits";
            description = "Agent Usage: open limits pane";
          }
          {
            key = "ctrl+shift+m";
            type = "plugin_action";
            command = "usagebar.refresh";
            description = "Agent Usage: refresh meters";
          }
        ];
      };

      ui = {
        show_agent_labels_on_pane_borders = true;
        toast.delivery = "terminal";

        sidebar.agents = {
          row_gap = 0;
          rows = [
            [
              "state_icon"
              {
                token = "agent";
                fg = "#eceff4";
                bold = true;
              }
              {
                token = "workspace";
                fg = "#b48ead";
              }
            ]
            [
              {
                token = "$provider";
                fg = "#88c0d0";
                bold = true;
              }
              {
                token = "$limit";
                fg = "#a3be8c";
                bold = true;
              }
            ]
            [
              {
                token = "$cache_high";
                fg = "#a3be8c";
              }
              {
                token = "$cache_mid";
                fg = "#ebcb8b";
              }
              {
                token = "$cache_low";
                fg = "#bf616a";
              }
            ]
            [
              {
                token = "$context";
                fg = "#81a1c1";
              }
            ]
          ];
        };
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

    home.activation.herdrPlugins = config.lib.dag.entryAfter [ "herdrConfig" ] ''
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          _: path: "run ${cfg.package}/bin/herdr plugin link ${lib.escapeShellArg (toString path)}"
        ) cfg.plugins
      )}
    '';
  };
}
