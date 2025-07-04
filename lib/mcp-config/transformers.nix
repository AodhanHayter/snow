# Transformation functions for different MCP format outputs
{ lib, ... }:

with lib;
{
  # Convert base MCP config to Anthropic format (essentially a passthrough)
  toAnthropicFormat = mcpConfig: mcpConfig;

  # Convert base MCP config to OpenCode format
  # If serverKey is provided, the servers will be nested under mcp.${serverKey}
  # If not provided, the servers will be directly under mcp
  toOpenCodeFormat =
    mcpConfig: serverKey:
    let
      # Transform a single server config from base to OpenCode format
      transformServer =
        name: server:
        let
          # Create command array, including the command and all args
          commandParts =
            if builtins.isString server.command then
              [ server.command ] ++ (server.args or [ ])
            else
              server.command ++ (server.args or [ ]);
        in
        {
          type = "local";
          command = commandParts;
          # Rename env to environment if it exists
          ${if server ? env then "environment" else null} = server.env or { };
        };

      # Transform all servers
      transformedServers = mapAttrs transformServer mcpConfig;

      # Create the mcp attribute based on whether serverKey is provided
      mcpAttr = if serverKey != null then { ${serverKey} = transformedServers; } else transformedServers;
    in
    mcpAttr;
}
