# Generation of MCP server configurations with format transformations
{ lib, ... }:

let
  base = import ./base.nix { inherit lib; };
  transformers = import ./transformers.nix { inherit lib; };
in

{
  # Generate base MCP server configurations
  mcp = {
    mkMcpConfig = base.mkMcpConfig;

    asAnthropicFormat =
      { config, pkgs }: transformers.toAnthropicFormat base.mkMcpConfig { inherit config pkgs; };

    asOpenCodeFormat =
      {
        config,
        pkgs,
        serverKey ? null,
      }:
      transformers.toOpenCodeFormat (base.mkMcpConfig { inherit config pkgs; }) serverKey;
  };
}
