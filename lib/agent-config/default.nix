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
      mkEnabled
      ;

    # Bash PreToolUse hooks shared by agents that use the claude hook schema.
    # Order is load order and it matters: rtk rewrites the command, dcg audits
    # the command that actually executes.
    mkBashGuardHooks =
      guards:
      optional guards.rtk.enable {
        type = "command";
        command = guards.rtk.command;
      }
      ++ optional guards.dcg.enable {
        type = "command";
        command = guards.dcg.command;
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

    # Rewrite a canonical 'plugin@marketplace' id into codex's marketplace naming.
    mkCodexPluginId =
      id:
      let
        parts = splitString "@" id;
      in
      if length parts == 2 && elemAt parts 1 == "caveman" then "${head parts}@caveman-repo" else id;

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

    # Flatten skill collections into name -> directory.
    mkSkillLinks =
      sources:
      foldl' (
        acc: sourceName:
        let
          s = sources.${sourceName};
          prefix = if s.subdir == "" then "" else "${s.subdir}/";
        in
        acc
        // listToAttrs (
          map (skillName: {
            name = skillName;
            value = "${s.src}/${prefix}${skillName}";
          }) s.names
        )
      ) { } (attrNames sources);

    # Mirror flattened skills into an agent's skills directory.
    mkSkillFiles =
      root: skills: mapAttrs' (name: src: nameValuePair "${root}/${name}" { source = src; }) skills;
  };
}
