# Generation of base MCP server configurations
{ lib, ... }:

{
  # Generate base MCP server configurations
  mkMcpConfig =
    {
      config,
      pkgs,
      extraServers ? { },
    }:
    {
      nixos = {
        command = "nix";
        args = [
          "run"
          "github:utensils/mcp-nixos"
          "--"
        ];
      };
      # playwright = {
      #   command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
      #   args = [ ];
      # };
    }
    // extraServers;
}
