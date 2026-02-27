{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.modernage;
let
  cfg = config.modernage.cli-apps.claude-code-work;
  homeDir = config.home.homeDirectory;

  # All work-specific configuration in one place
  bedrockConfig = {
    awsRegion = "us-east-1";
    awsProfile = "ClaudeCode";
    otelEndpoint = "https://claude-otel.kyruus.com";
    otelProtocol = "http/protobuf";
    otelResourceAttrs = "department=engineering,team.id=default,cost_center=default,organization=default";
  };

  # Platform-specific binary suffix
  suffix =
    if pkgs.stdenv.hostPlatform.isAarch64 && pkgs.stdenv.hostPlatform.isDarwin then
      "macos-arm64"
    else if pkgs.stdenv.hostPlatform.isx86_64 && pkgs.stdenv.hostPlatform.isDarwin then
      "macos-intel"
    else if pkgs.stdenv.hostPlatform.isAarch64 && pkgs.stdenv.hostPlatform.isLinux then
      "linux-arm64"
    else if pkgs.stdenv.hostPlatform.isx86_64 && pkgs.stdenv.hostPlatform.isLinux then
      "linux-x64"
    else
      throw "claude-code-work: unsupported platform";

  wrapperScript = pkgs.writeShellScriptBin "claude-work" ''
    export CLAUDE_CODE_USE_BEDROCK=1
    export AWS_PROFILE=${bedrockConfig.awsProfile}
    export AWS_REGION=${bedrockConfig.awsRegion}
    ${optionalString (cfg.model != "") "export ANTHROPIC_MODEL='${cfg.model}'"}
    ${optionalString (cfg.smallFastModel != "") "export ANTHROPIC_SMALL_FAST_MODEL='${cfg.smallFastModel}'"}
    export CLAUDE_CODE_ENABLE_TELEMETRY=1
    export OTEL_METRICS_EXPORTER=otlp
    export OTEL_LOGS_EXPORTER=otlp
    export OTEL_EXPORTER_OTLP_PROTOCOL="${bedrockConfig.otelProtocol}"
    export OTEL_EXPORTER_OTLP_ENDPOINT="${bedrockConfig.otelEndpoint}"
    export OTEL_RESOURCE_ATTRIBUTES="${bedrockConfig.otelResourceAttrs}"
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';
in
{
  options.modernage.cli-apps.claude-code-work = {
    enable = mkBoolOpt false "Whether to enable work (Bedrock) Claude Code configuration.";

    model = mkOpt types.str "" ''
      Bedrock model ID for the primary Claude model (sets ANTHROPIC_MODEL).
      Leave empty for the Bedrock default (global.anthropic.claude-sonnet-4-6).
      Cross-region inference profile IDs:
        - us.anthropic.claude-opus-4-6-v1
        - us.anthropic.claude-sonnet-4-6
        - us.anthropic.claude-haiku-4-5-20251001-v1:0
    '';

    smallFastModel = mkOpt types.str "" ''
      Bedrock model ID for the small/fast model (sets ANTHROPIC_SMALL_FAST_MODEL).
      Leave empty for the Bedrock default (us.anthropic.claude-haiku-4-5-20251001-v1:0).
    '';

    repoPath = mkOption {
      type = types.str;
      description = ''
        Path to local checkout of kyruushealth-claude-code repo.
        Binaries and config are copied at activation time (not Nix eval time),
        so this path is only needed when running darwin-rebuild/home-manager switch.
        Clone the repo first:
          git clone git@github.com:healthsparq/kyruushealth-claude-code <path>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ wrapperScript ];

    # Copy binaries + config at activation time (avoids pure eval restrictions)
    home.activation.claudeBedrockSetup =
      config.lib.dag.entryAfter [ "writeBoundary" ] ''
        REPO="${cfg.repoPath}"
        DEST="${homeDir}/claude-code-with-bedrock"

        if [ ! -d "$REPO" ]; then
          errorEcho "claude-code-work: repo not found at $REPO"
          errorEcho "Clone it: git clone git@github.com:healthsparq/kyruushealth-claude-code $REPO"
          exit 1
        fi

        CRED="$REPO/credential-process-${suffix}"
        OTEL="$REPO/otel-helper-${suffix}"
        CONF="$REPO/config.json"

        if [ ! -f "$CRED" ]; then
          errorEcho "claude-code-work: credential-process-${suffix} not found in $REPO"
          exit 1
        fi

        if [ ! -f "$CONF" ]; then
          errorEcho "claude-code-work: config.json not found in $REPO"
          exit 1
        fi

        run mkdir -p "$DEST"
        run cp "$CRED" "$DEST/credential-process"
        run chmod +x "$DEST/credential-process"
        run cp "$CONF" "$DEST/config.json"

        if [ -f "$OTEL" ]; then
          run cp "$OTEL" "$DEST/otel-helper"
          run chmod +x "$DEST/otel-helper"
        fi
      '';

    # Append ClaudeCode AWS profile if not present
    home.activation.claudeBedrockAwsProfile =
      config.lib.dag.entryAfter [ "claudeBedrockSetup" ] ''
        if ! grep -q '\[profile ClaudeCode\]' "${homeDir}/.aws/config" 2>/dev/null; then
          run mkdir -p "${homeDir}/.aws"
          run bash -c 'cat >> "${homeDir}/.aws/config" << EOF

[profile ClaudeCode]
credential_process = ${homeDir}/claude-code-with-bedrock/credential-process
region = ${bedrockConfig.awsRegion}
EOF'
        fi
      '';

    # otelHeadersHelper in settings.json — only invoked when telemetry is enabled (work mode)
    programs.claude-code.settings.otelHeadersHelper = "~/claude-code-with-bedrock/otel-helper";
  };
}
