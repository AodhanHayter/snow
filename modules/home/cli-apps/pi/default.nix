{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.pi;
  shared = config.modernage.coding-agents;
  dcg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dcg;

  managedSettings = {
    defaultProvider = cfg.provider;
    defaultThinkingLevel = cfg.thinkingLevel;
    # pi-dcg pings its own telemetry endpoint unless pi telemetry is off.
    enableInstallTelemetry = false;

    # What `pi install` writes. pi npm-installs anything missing here at session
    # start, so listing them is enough — no activation-time install step. Update
    # with `pi update --extensions`; nix owns the list, so removals apply too.
    # An extension must never appear here *and* in `extensions` above: loading it
    # twice fails with a tool name conflict.
    packages = cfg.packages;

    # Shared agent resource tree: skills are the same SKILL.md format, and pi
    # prompt templates use the same frontmatter as the shared commands.
    skills = [ "${shared.resourceDir}/skills" ];
    prompts = optional (shared.commandsDir != null) "${shared.resourceDir}/commands";
    enableSkillCommands = true;
  }
  // optionalAttrs (cfg.model != null) { defaultModel = cfg.model; };
in
{
  options.modernage.cli-apps.pi = {
    enable = mkBoolOpt false "Whether or not to install and configure the pi coding agent.";

    provider = mkOpt types.str "anthropic" "Default pi provider.";
    model = mkOpt (types.nullOr types.str) null "Default pi model id; null lets pi choose.";
    thinkingLevel = mkOpt types.str "high" "Default pi thinking level.";
    extensions = mkOpt (types.listOf types.path) [
    ] "Store-pinned extension sources passed to pi via --extension.";

    # Order is load order, and it matters: rtk-optimizer rewrites bash commands,
    # so it must run before pi-dcg audits the command that actually executes.
    packages = mkOpt (types.listOf types.str) [
      "npm:pi-rtk-optimizer"
      "npm:pi-dcg"
      "npm:@gotgenes/pi-anthropic-auth"
      "npm:pi-vim"
    ] "Extension sources pi installs itself into ~/.pi/agent/npm.";

    settings = mkOpt types.attrs { } "Extra settings merged into ~/.pi/agent/settings.json.";
  };

  config = mkIf cfg.enable {
    modernage.coding-agents.enable = true;

    programs.pi.coding-agent = {
      enable = true;

      # pi only discovers context files from cwd upwards plus
      # ~/.pi/agent/AGENTS.md, so ship the shared instructions via
      # --append-system-prompt instead.
      rules = shared.instructions;
      inherit (cfg) extensions;
      settings = recursiveUpdate managedSettings cfg.settings;

      # pi-dcg is configured by environment only; it reads no settings.json keys.
      environment = {
        # Point at the nix-built binary rather than resolving "dcg" on PATH.
        PI_DCG_BIN.value = "${dcg}/bin/dcg";

        # The bridge allows the command when dcg can't be reached or errors.
        # Fail closed instead: a guard that silently stops guarding is worse
        # than one that blocks until it's fixed.
        PI_DCG_ON_ERROR.value = "block";
      };
    };
  };
}
