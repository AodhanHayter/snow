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
        mcpServers = mcp.asAnthropicFormat {
          inherit config pkgs;
        };
      };
    };
  };
}
