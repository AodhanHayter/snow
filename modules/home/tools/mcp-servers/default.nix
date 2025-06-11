{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
with lib.modernage;
with inputs;
let
  homeDir =
    if pkgs.stdenv.isDarwin then
      "/Users/${config.modernage.user.name}"
    else
      "/home/${config.modernage.user.name}";

  cfg = config.modernage.tools.mcp-servers;

  claudeDesktopConfig = {
    mcpServers = {
      filesystem = {
        command = "${pkgs.mcp-server-filesystem}/bin/mcp-server-filesystem";
        args = [ homeDir ];
      };
      git = {
        command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        args = [ ];
      };
      playwright = {
        command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
        args = [ ];
      };
      # github = {
      #   command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
      #   args = [ "stdio" ];
      #   env = {
      #     GITHUB_PERSONAL_TOKEN = ""
      #   }
      # };
    };
  };

  claudDesktopConfigPath =
    if pkgs.stdenv.isDarwin then
      "Library/Application Support/Claude/claude_desktop_config.json"
    else
      ".config/claude-desktop/config.json";

in
{
  options.modernage.tools.mcp-servers = with types; {
    enable = mkBoolOpt false "Whether or not to enable mcp-servers.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mcp-server-filesystem
      mcp-server-git
      playwright-mcp
      # github-mcp-server
    ];

    home.file."${claudDesktopConfigPath}" = {
      text = builtins.toJSON claudeDesktopConfig;
    };
  };
}
