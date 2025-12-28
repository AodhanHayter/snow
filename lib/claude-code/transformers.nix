# Transform Nix marketplace defs to Claude Code JSON format
{ lib, ... }:

with lib;

{
  # Convert single marketplace def to Claude format
  # Input: { source = { type = "github"; url = "owner/repo"; }; }
  # Output: { source = { source = "github"; repo = "owner/repo"; }; installLocation = "..."; lastUpdated = "..."; }
  toMarketplaceFormat = name: marketplace:
    let
      sourceType = marketplace.source.type or "github";
    in
    {
      source = {
        source = sourceType;
        repo = marketplace.source.url;
      };
      installLocation = "~/.claude/plugins/marketplaces/${name}";
      lastUpdated = "1970-01-01T00:00:00.000Z"; # Placeholder - Claude updates on first fetch
    };

  # Transform all marketplaces to known_marketplaces.json format
  mkKnownMarketplaces = marketplaces:
    mapAttrs (name: m: {
      source = {
        source = m.source.type or "github";
        repo = m.source.url;
      };
      installLocation = "~/.claude/plugins/marketplaces/${name}";
      lastUpdated = "1970-01-01T00:00:00.000Z"; # Placeholder - Claude updates on first fetch
    }) marketplaces;
}
