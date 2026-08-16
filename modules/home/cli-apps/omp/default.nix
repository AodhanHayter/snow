{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.omp;
  shared = config.modernage.coding-agents;

  managedSettings = {
    # Shared agent resource tree: skills use the same SKILL.md format, and omp
    # scans customDirectories one level deep for */SKILL.md — exactly the shape
    # the shared tree materializes.
    skills.customDirectories = [ "${shared.resourceDir}/skills" ];
  }
  // optionalAttrs (cfg.model != null) { modelRoles.default = cfg.model; }
  // optionalAttrs (cfg.thinkingLevel != null) { defaultThinkingLevel = cfg.thinkingLevel; };

  # Shipped as a settings *overlay*, not as ~/.omp/agent/config.yml: writing
  # that path from nix makes it a read-only store symlink, so `/settings` and
  # `omp config set` fail. Overlays sit above the global config in precedence
  # and are never persisted, so nix keeps ownership of the keys it declares
  # while omp keeps a writable config file for everything else.
  configOverlay = (pkgs.formats.yaml { }).generate "omp-config-overlay.yml" managedSettings;
in
{
  options.modernage.cli-apps.omp = {
    enable = mkBoolOpt false "Whether or not to install and configure the omp (oh-my-pi) coding agent.";

    # Both null by default so omp's own defaults apply and stay runtime-editable;
    # setting either here pins it against `omp config set`.
    model = mkOpt (types.nullOr types.str) null "Model selector pinned to the default role.";
    thinkingLevel = mkOpt (types.nullOr types.str) null "Thinking level pinned as the default.";

    settings = mkOpt types.attrs { } "Extra settings merged into the nix-owned config overlay.";
  };

  config = mkIf cfg.enable {
    modernage.coding-agents.enable = true;

    programs.omp.enable = true;

    home.sessionVariables.PI_CONFIG_FILES = "${configOverlay}";

    # omp discovers context files from cwd upwards only, so the shared
    # instructions ship as APPEND_SYSTEM.md: it is appended to the default
    # system prompt, where SYSTEM.md would replace the instruction template.
    # Commands and subagents have no path setting, so they mirror into the
    # agent dir omp scans.
    home.file = {
      ".omp/agent/APPEND_SYSTEM.md".text = shared.instructions;
    }
    // optionalAttrs (shared.commandsDir != null) {
      ".omp/agent/commands".source = shared.commandsDir;
    }
    // optionalAttrs (shared.agentsDir != null) {
      ".omp/agent/agents".source = shared.agentsDir;
    };
  };
}
