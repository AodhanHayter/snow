##
## Agent-agnostic configuration shared by every coding agent (claude-code,
## codex-cli, pi, ...). Holds the concepts once — instructions, prompt
## commands, subagents, skills, plugin marketplaces, env, bash guards — and
## materializes them under a neutral `resourceDir` that any agent can point
## at. Agent modules default their own options to these values, so per-agent
## overrides still work.
##
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
  cfg = config.modernage.coding-agents;
  homeDir = config.home.homeDirectory;
  relDir = removePrefix "${homeDir}/" cfg.resourceDir;
in
{
  options.modernage.coding-agents = {
    enable = mkBoolOpt false "Whether to materialize the shared agent resource tree.";

    resourceDir = mkOpt types.str "${homeDir}/.config/coding-agents" ''
      Agent-neutral directory holding the shared instructions, prompt commands
      and skills. Agents that can read resources from an arbitrary path (pi)
      point here; agents that only read their own home dir (claude, codex)
      mirror these entries into it.
    '';

    instructionFiles = mkOpt (types.listOf types.path) [
      ./instructions/AGENTS.md
      ./instructions/rtk-awareness.md
    ] "Files concatenated into the global instruction text.";

    instructions = mkOpt types.lines (concatMapStringsSep "\n\n" builtins.readFile
      cfg.instructionFiles
    ) "Global instruction text handed to every agent.";

    # Both default to null when the directory is absent: an empty dir is not
    # tracked by git, so it never makes it into the flake source.
    commandsDir = mkOpt (types.nullOr types.path) (
      if builtins.pathExists ./commands then ./commands else null
    ) "Directory of prompt/slash command definitions, or null for none.";

    agentsDir = mkOpt (types.nullOr types.path) (
      if builtins.pathExists ./agents then ./agents else null
    ) "Directory of subagent definitions, or null for none.";

    skills = {
      local = mkOpt (types.attrsOf types.path) {
        codex-computer-use = ./skills/codex-computer-use;
      } "Skills shipped in this repo, as name -> directory.";

      external = mkOpt (types.attrsOf types.path) {
        herdr = "${inputs.herdr-skill}/skills/herdr";

        # Hunk bundles its skill inside the package output; reference the
        # package so it tracks nix-managed hunk updates.
        hunk-review = "${inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk}/skills/hunk-review";
      } "Skills pulled from a single flake input or package, as name -> directory.";

      sources = mkOption {
        type = types.attrsOf agentConfig.skillSourceModule;
        default = {
          anthropics = {
            src = inputs.anthropics-skills;
            subdir = "skills";
            names = [ ];
          };
          mattpocock-engineering = {
            src = inputs.mattpocock-skills;
            subdir = "skills/engineering";
            names = [
              "diagnosing-bugs"
              "domain-modeling"
              "codebase-design"
              "code-review"
              "grill-with-docs"
              "improve-codebase-architecture"
              "prototype"
              "research"
              "tdd"
              "to-spec"
              "to-tickets"
              "wayfinder"
            ];
          };
          humanlayer = {
            src = inputs.humanlayer-skills;
            subdir = "plugins/show-me/skills";
            names = [ "show-me" ];
          };
          simple-english = {
            src = inputs.simple-english-skill;
            subdir = "skills";
            names = [ "simple-english" ];
          };
          mattpocock-productivity = {
            src = inputs.mattpocock-skills;
            subdir = "skills/productivity";
            names = [
              "grill-me"
              "grilling"
              "handoff"
              "writing-great-skills"
            ];
          };
        };
        description = "Skill collections to pick individual skill folders out of.";
      };

      resolved = mkOpt (types.attrsOf types.path) (
        cfg.skills.local // cfg.skills.external // agentConfig.mkSkillLinks cfg.skills.sources
      ) "All skills, flattened to name -> directory. Agents mirror this into their own skills dir.";
    };

    env = mkOpt (types.attrsOf types.str) {
      CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-5";
      CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    } "Environment shared by every agent session.";

    plugins = {
      marketplaces = mkOption {
        type = types.attrsOf agentConfig.marketplaceModule;
        default = {
          "anthropics/claude-plugins-official" = {
            source = {
              type = "github";
              url = "anthropics/claude-plugins-official";
            };
            flakeInput = inputs.claude-plugins-official;
          };
          "anthropics/skills" = {
            source = {
              type = "github";
              url = "anthropics/skills";
            };
            flakeInput = inputs.anthropics-skills;
          };
          "JuliusBrussee/caveman" = {
            source = {
              type = "github";
              url = "JuliusBrussee/caveman";
            };
            flakeInput = inputs.caveman;
          };
          "openai-codex" = {
            source = {
              type = "github";
              url = "openai/codex-plugin-cc";
            };
            flakeInput = inputs.codex-plugin-cc;
          };
        };
        description = "Plugin marketplaces to register with every agent that supports them.";
      };

      enabled = mkOption {
        type = types.attrsOf types.bool;
        default = agentConfig.mkEnabled agentConfig.commonPlugins "claude-plugins-official" // {
          "caveman@caveman" = true;
          "codex@openai-codex" = true;
        };
        description = ''
          Canonical plugin set, in 'plugin-name@marketplace-name' form. Agent
          modules translate the ids and drop what they cannot resolve.
        '';
      };
    };

    # Bash guards run as PreToolUse hooks by every agent that supports hooks.
    # Order matters: rtk rewrites the command, dcg audits what actually runs.
    guards = {
      rtk = {
        enable = mkBoolOpt true "Whether to run the rtk token-saving rewrite hook.";
        command = mkOpt types.str "rtk hook claude" "Command implementing the rtk hook.";
      };

      dcg = {
        enable = mkBoolOpt true "Whether to run the dcg command guard hook.";
        command = mkOpt types.str "dcg" "Command implementing the dcg guard.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.file =
      agentConfig.mkSkillFiles "${relDir}/skills" cfg.skills.resolved
      // optionalAttrs (cfg.commandsDir != null) {
        "${relDir}/commands".source = cfg.commandsDir;
      }
      // optionalAttrs (cfg.agentsDir != null) {
        "${relDir}/agents".source = cfg.agentsDir;
      }
      // {
        "${relDir}/AGENTS.md".text = cfg.instructions;
      };
  };
}
