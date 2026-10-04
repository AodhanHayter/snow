# Shared MCP servers, rendered per agent format.
{ lib, ... }:

with lib;
let
  servers = pkgs: {
    nixos.command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
  };
in
{
  mcp = {
    # Claude/pi `mcpServers` shape.
    asAnthropicFormat = { pkgs }: servers pkgs;

    asOpenCodeFormat =
      { pkgs }:
      mapAttrs (
        _: server:
        {
          type = "local";
          command = [ server.command ] ++ server.args or [ ];
        }
        // optionalAttrs (server ? env) { environment = server.env; }
      ) (servers pkgs);

    # Codex only accepts these keys under [mcp_servers.<name>].
    asCodexFormat =
      { pkgs }:
      mapAttrs (
        _: server:
        {
          inherit (server) command;
          args = server.args or [ ];
        }
        // optionalAttrs (server ? env) { inherit (server) env; }
      ) (servers pkgs);
  };
}
