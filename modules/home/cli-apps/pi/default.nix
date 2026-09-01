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

    # pi-subagents model tiering (docs/models.md): cheap recon, mid-tier
    # execution, top reasoning only for oracle. Without this every subagent
    # inherits the (expensive) parent session model. Custom agents that pin
    # `model:` in frontmatter still win over defaultModel.
    subagents = {
      defaultModel = "anthropic/claude-opus-5";
      defaultThinking = "high";
      agentOverrides = {
        scout = {
          model = "openai-codex/gpt-5.6-luna";
          thinking = "xhigh";
        };
        researcher = {
          model = "openai-codex/gpt-5.6-luna";
          thinking = "xhigh";
        };
        worker = {
          model = "openai-codex/gpt-5.6-luna";
          thinking = "xhigh";
          fallbackModels = [ "anthropic/claude-sonnet-5" ];
        };
        reviewer = {
          model = "openai-codex/gpt-5.6-sol";
          fallbackModels = [ "anthropic/claude-opus-5" ];
        };
        oracle = {
          model = "openai-codex/gpt-5.6-sol";
          thinking = "high";
          fallbackModels = [ "anthropic/claude-fable-5" ];
        };
      };
    };
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
      "npm:@dietrichgebert/ponytail"
      "npm:pi-web-access"
      "npm:pi-subagents"
      "npm:@ff-labs/pi-fff"
      "npm:pi-context-view"
      "npm:pi-mcp-adapter"
      "npm:@narumitw/pi-btw"
      "npm:@narumitw/pi-goal"
      "npm:@quintinshaw/pi-dynamic-workflows"
      "npm:pi-clarify"
      "npm:pi-agent-browser-native"
      "npp:pi-mermaid"
    ] "Extension sources pi installs itself into ~/.pi/agent/npm.";

    settings = mkOpt types.attrs { } "Extra settings merged into ~/.pi/agent/settings.json.";

    subagentConfig = mkOpt types.attrs { } ''
      pi-subagents extension config written to
      ~/.pi/agent/extensions/subagent/config.json (concurrency, fleetView,
      timeouts, missions, artifactDir, ...). Settings-level subagents.* keys
      (models, agentOverrides) belong in `settings` instead.
    '';
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

    # pi-subagents only discovers user agents under ~/.pi/agent/agents;
    # link the shared agent definitions there so deep-reasoner/fast-worker
    # are runnable as pi subagents too.
    home.file.".pi/agent/agents" = mkIf (shared.agentsDir != null) {
      source = shared.agentsDir;
    };

    home.file.".pi/agent/extensions/subagent/config.json" = mkIf (cfg.subagentConfig != { }) {
      text = builtins.toJSON cfg.subagentConfig;
    };
  };
}
