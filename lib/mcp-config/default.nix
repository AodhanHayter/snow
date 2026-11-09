# Shared MCP servers, rendered per agent format.
{ lib, ... }:

with lib;
let
  servers = pkgs: {
    nixos.command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    browse = {
      command = "${pkgs.modernage.browse}/bin/browse";
      args = [ "mcp" ];
    };
  };
in
{
  mcp = {
    # Claude/pi `mcpServers` shape.
    asAnthropicFormat = { pkgs }: servers pkgs;

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
