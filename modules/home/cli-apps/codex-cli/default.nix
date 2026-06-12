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
  cfg = config.modernage.cli-apps.codex-cli;
  homeDir = config.home.homeDirectory;
  agentDefaults = agentConfig.defaults inputs;
  dcg = inputs.self.packages.${pkgs.system}.dcg;

  rtkRewriteScript = pkgs.writeShellScript "rtk-rewrite" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.jq
        pkgs.rtk
      ]
    }:$PATH"
    ${builtins.readFile ../claude-code/rtk-rewrite.sh}
  '';

  dcgCodexHookScript = pkgs.writeShellScript "dcg-codex-hook" ''
    set -euo pipefail

    payload="$(cat)"
    output="$(printf '%s' "$payload" | DCG_NO_COLOR=true ${dcg}/bin/dcg 2>&1 || true)"

    printf '%s' "$output" | ${pkgs.python3}/bin/python3 -c '
    import json
    import sys

    data = sys.stdin.read()
    decoder = json.JSONDecoder()
    for i, ch in enumerate(data):
        if ch != "{":
            continue
        try:
            obj, _ = decoder.raw_decode(data[i:])
        except json.JSONDecodeError:
            continue
        hook_output = obj.get("hookSpecificOutput") or {}
        decision = hook_output.get("permissionDecision")
        reason = hook_output.get("permissionDecisionReason")
        if decision:
            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": decision,
                    "permissionDecisionReason": reason,
                }
            }, separators=(",", ":")))
        break
    '
  '';

  hooksJson = (pkgs.formats.json { }).generate "codex-hooks.json" {
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${rtkRewriteScript}";
            }
            {
              type = "command";
              command = "${dcgCodexHookScript}";
            }
          ];
        }
      ];
    };
  };

  agentsFile = pkgs.writeText "codex-agents.md" (
    builtins.readFile ../claude-code/CLAUDE.md
    + "\n\n"
    + builtins.readFile ../claude-code/rtk-awareness.md
  );

  # Upstream caveman dropped its codex-native marketplace manifest
  # (.agents/plugins/marketplace.json) in 25d22f8; codex can't enumerate the
  # claude-style manifest (plugin source "./"), so `codex plugin add` fails.
  # Wrap the input and restore the manifest until upstream ships one again.
  cavemanMarketplaceJson = pkgs.writeText "caveman-marketplace.json" (
    builtins.toJSON {
      name = "caveman-repo";
      interface.displayName = "Caveman Repo";
      plugins = [
        {
          name = "caveman";
          source = {
            source = "local";
            path = "./plugins/caveman";
          };
          policy = {
            installation = "AVAILABLE";
            authentication = "ON_INSTALL";
          };
          category = "Productivity";
        }
      ];
    }
  );

  cavemanCodexMarketplace = pkgs.runCommand "caveman-codex-marketplace" { } ''
    mkdir -p $out/.agents/plugins
    cp -R ${inputs.caveman}/plugins $out/plugins
    cp ${cavemanMarketplaceJson} $out/.agents/plugins/marketplace.json
  '';

  codexMarketplaces =
    cfg.plugins.marketplaces
    // optionalAttrs (cfg.plugins.marketplaces ? "JuliusBrussee/caveman") {
      "JuliusBrussee/caveman" = cfg.plugins.marketplaces."JuliusBrussee/caveman" // {
        flakeInput = cavemanCodexMarketplace;
      };
    };

  codexConfig = recursiveUpdate {
    inherit (cfg) model personality;
    model_reasoning_effort = cfg.reasoningEffort;
    features = {
      hooks = true;
      unified_exec = true;
    };
    marketplaces = agentConfig.mkCodexMarketplaces codexMarketplaces;
    plugins = cfg.plugins.enabled;
    mcp_servers = mcp.asCodexFormat { inherit config pkgs; };
    shell_environment_policy = {
      "inherit" = "core";
      set = agentDefaults.env // {
        CLAUDE_CODE_ENABLE_TELEMETRY = "0";
      };
    };
  } cfg.extraConfig;

  configToml = (pkgs.formats.toml { }).generate "codex-config.toml" codexConfig;
  skillFiles = agentConfig.mkSkillFiles ".codex/skills" cfg.skills.sources;
  pythonWithToml = pkgs.python3.withPackages (ps: [ ps.tomli-w ]);
  mergeCodexConfigScript = pkgs.writeText "merge-codex-config.py" ''
    import pathlib
    import sys
    import tomllib
    import tomli_w

    target = pathlib.Path(sys.argv[1])
    managed = pathlib.Path(sys.argv[2])

    def load(path):
        if not path.exists():
            return {}
        with path.open("rb") as f:
            return tomllib.load(f)

    def merge(base, overlay):
        result = dict(base)
        for key, value in overlay.items():
            if isinstance(value, dict) and isinstance(result.get(key), dict):
                result[key] = merge(result[key], value)
            else:
                result[key] = value
        return result

    merged = merge(load(target), load(managed))
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("wb") as f:
        tomli_w.dump(merged, f)
  '';
  pluginInstallCommands = concatMapStringsSep "\n" (plugin: ''
    run ${pkgs.coreutils}/bin/env CODEX_HOME="${homeDir}/.codex" ${pkgs.codex-cli}/bin/codex plugin add ${escapeShellArg plugin} >/dev/null
  '') (attrNames cfg.plugins.enabled);
in
{
  options.modernage.cli-apps.codex-cli = {
    enable = mkBoolOpt false "Whether or not to install OpenAI Codex CLI.";

    model = mkOpt types.str "gpt-5.5" "Default Codex model.";
    reasoningEffort = mkOpt types.str "high" "Default Codex reasoning effort.";
    personality = mkOpt types.str "pragmatic" "Default Codex personality.";

    plugins = {
      marketplaces = mkOption {
        type = types.attrsOf agentConfig.marketplaceModule;
        default = agentDefaults.plugins.marketplaces;
        description = "Plugin marketplaces to register in Codex.";
      };

      enabled = mkOption {
        type = types.attrsOf (
          types.submodule {
            options.enabled = mkOption {
              type = types.bool;
              default = true;
              description = "Whether the plugin is enabled.";
            };
          }
        );
        default = agentDefaults.plugins.codexEnabled;
        description = "Codex plugins to enable in format 'plugin-name@marketplace-name'.";
      };
    };

    skills.sources = mkOption {
      type = types.attrsOf agentConfig.skillSourceModule;
      default = agentDefaults.skills.sources;
      description = "External skill sources to symlink into ~/.codex/skills.";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra config merged into ~/.codex/config.toml.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      codex-cli
      rtk
      dcg
    ];

    home.file = skillFiles;

    home.activation.codexConfigSeed = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${homeDir}/.codex"

      configTarget="${homeDir}/.codex/config.toml"
      if [ -L "$configTarget" ] && [[ "$(readlink "$configTarget")" == /nix/store/* ]]; then
        run rm -f "$configTarget"
      fi
      run ${pythonWithToml}/bin/python ${mergeCodexConfigScript} "$configTarget" ${configToml}
      run chmod 0600 "$configTarget"

      hooksTarget="${homeDir}/.codex/hooks.json"
      if [ ! -e "$hooksTarget" ] || { [ -L "$hooksTarget" ] && [[ "$(readlink "$hooksTarget")" == /nix/store/* ]]; }; then
        run rm -f "$hooksTarget"
        run install -m 0644 ${hooksJson} "$hooksTarget"
      fi

      agentsTarget="${homeDir}/.codex/AGENTS.md"
      if [ ! -e "$agentsTarget" ] || { [ -L "$agentsTarget" ] && [[ "$(readlink "$agentsTarget")" == /nix/store/* ]]; }; then
        run rm -f "$agentsTarget"
        run install -m 0644 ${agentsFile} "$agentsTarget"
      fi

      ${pluginInstallCommands}
    '';
  };
}
