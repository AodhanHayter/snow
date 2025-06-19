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
  user = config.modernage.user;
  home-directory = if pkgs.stdenv.isDarwin then "/Users/${user.name}" else "/home/${user.name}";

  cfg = config.modernage.tools.mcp-servers;

  claudDesktopConfigPath =
    if pkgs.stdenv.isDarwin then
      "${home-directory}/Library/Application Support/Claude/claude_desktop_config.json"
    else
      ".config/claude-desktop/config.json";

in
{
  options.modernage.tools.mcp-servers = with types; {
    enable = mkBoolOpt false "Whether or not to enable mcp-servers.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      context7-mcp
      github-mcp-server
      # mcp-server-filesystem
      mcp-server-git
      # mcp-server-postgres
      playwright-mcp
    ];

    sops.templates."claude_desktop_config.json" = {
      mode = "0600";
      path = claudDesktopConfigPath;
      content = builtins.toJSON {
        mcpServers = {
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
          # filesystem = {
          #   command = "${pkgs.mcp-server-filesystem}/bin/mcp-server-filesystem";
          #   args = [ home-directory ];
          # };
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
          # postgres = {
          #   command = "${pkgs.mcp-server-postgres}/bin/mcp-server-postgres";
          #   args = [ ];
          # };
        };
      };
    };
  };
}
