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
      brave-search = {
        command = "${pkgs.mcp-server-brave-search}/bin/mcp-server-brave-search";
        args = [ ];
        env = {
          BRAVE_API_KEY = config.sops.placeholder."search/brave_api_key";
        };
      };
      Context7 = {
        command = "${pkgs.context7-mcp}/bin/context7-mcp";
        args = [ ];
      };
      git = {
        command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        args = [ ];
      };
      github = {
        command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = config.sops.placeholder."github/token";
        };
      };
      playwright = {
        command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
        args = [ ];
      };
    }
    // extraServers;
}

