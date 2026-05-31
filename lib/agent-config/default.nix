{ lib, ... }:

with lib;
let
  marketplaceModule = types.submodule {
    options = {
      source = mkOption {
        type = types.submodule {
          options = {
            type = mkOption {
              type = types.enum [
                "github"
                "git"
                "local"
              ];
              default = "github";
              description = "Marketplace source type.";
            };
            url = mkOption {
              type = types.str;
              default = "";
              description = "Marketplace source URL or path.";
            };
          };
        };
        description = "Marketplace source configuration.";
      };
      flakeInput = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Nix-managed marketplace source.";
      };
    };
  };

  skillSourceModule = types.submodule {
    options = {
      src = mkOption {
        type = types.path;
        description = "Path containing skill folders.";
      };
      subdir = mkOption {
        type = types.str;
        default = "";
        description = "Subdir within src holding skill folders.";
      };
      names = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Skill folder names to symlink.";
      };
    };
  };

  getMarketplaceName = name: last (splitString "/" name);

  commonPlugins = [
    "plugin-dev"
    "playground"
    "pr-review-toolkit"
    "claude-md-management"
    "code-simplifier"
    "commit-commands"
    "feature-dev"
    "frontend-design"
  ];

  mkEnabled =
    plugins: marketplace:
    listToAttrs (
      map (plugin: {
        name = "${plugin}@${marketplace}";
        value = true;
      }) plugins
    );
in
{
  agentConfig = rec {
    inherit
      marketplaceModule
      skillSourceModule
      getMarketplaceName
      commonPlugins
      ;

    defaults = inputs: {
      env = {
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        DIRENV_LOG_FORMAT = "";
        DIRENV_WARN_TIMEOUT = "0";
      };

      plugins = {
        marketplaces = {
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
          "AodhanHayter/claude-lsp-plugins" = {
            source = {
              type = "github";
              url = "AodhanHayter/claude-lsp-plugins";
            };
            flakeInput = inputs.claude-lsp-plugins;
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

        claudeEnabled = mkEnabled commonPlugins "claude-plugins-official" // {
          "nix-lsp@claude-lsp-plugins" = true;
          "python-lsp@claude-lsp-plugins" = true;
          "elixir-lsp@claude-lsp-plugins" = true;
          "swift-lsp@claude-lsp-plugins" = true;
          "caveman@caveman" = true;
          "codex@openai-codex" = true;
        };

        codexEnabled = mapAttrs (_: enabled: { inherit enabled; }) (
          mkEnabled commonPlugins "claude-plugins-official"
          // {
            "caveman@caveman-repo" = true;
          }
        );
      };

      skills.sources = {
        anthropics = {
          src = inputs.anthropics-skills;
          subdir = "skills";
          names = [ ];
        };
        mattpocock-engineering = {
          src = inputs.mattpocock-skills;
          subdir = "skills/engineering";
          names = [
            "diagnose"
            "grill-with-docs"
            "improve-codebase-architecture"
            "prototype"
            "tdd"
          ];
        };
        mattpocock-productivity = {
          src = inputs.mattpocock-skills;
          subdir = "skills/productivity";
          names = [
            "grill-me"
            "handoff"
          ];
        };
      };
    };

    mkClaudeExtraKnownMarketplaces =
      marketplaces:
      mapAttrs' (
        name: m:
        nameValuePair (getMarketplaceName name) {
          source = {
            source = if m.source.type == "github" then "github" else m.source.type;
            repo = m.source.url;
          };
        }
      ) marketplaces;

    mkClaudeMarketplaceSymlinks =
      marketplaces:
      mapAttrs' (
        name: marketplace:
        nameValuePair ".claude/plugins/marketplaces/${getMarketplaceName name}" {
          source = marketplace.flakeInput;
          force = true;
        }
      ) (filterAttrs (_: m: m.flakeInput != null) marketplaces);

    mkCodexMarketplaceName =
      name: if name == "JuliusBrussee/caveman" then "caveman-repo" else getMarketplaceName name;

    mkCodexMarketplaces =
      marketplaces:
      mapAttrs' (
        name: m:
        nameValuePair (mkCodexMarketplaceName name) {
          source_type =
            if m.flakeInput != null then
              "local"
            else if m.source.type == "github" then
              "git"
            else
              m.source.type;
          source =
            if m.flakeInput != null then
              toString m.flakeInput
            else if m.source.type == "github" then
              "https://github.com/${m.source.url}.git"
            else
              m.source.url;
        }
      ) marketplaces;

    mkSkillFiles =
      root: sources:
      foldl' (
        acc: sourceName:
        let
          s = sources.${sourceName};
          prefix = if s.subdir == "" then "" else "${s.subdir}/";
        in
        acc
        // listToAttrs (
          map (skillName: {
            name = "${root}/${skillName}";
            value.source = "${s.src}/${prefix}${skillName}";
          }) s.names
        )
      ) { } (attrNames sources);
  };
}
