# Claude Code plugin management functions
{ lib, ... }:

let
  marketplaces = import ./marketplaces.nix { inherit lib; };
  transformers = import ./transformers.nix { inherit lib; };
in
{
  claude = {
    # Default marketplace definitions
    defaultMarketplaces = marketplaces.defaults;

    # Transform marketplace def to Claude JSON format
    toMarketplaceFormat = transformers.toMarketplaceFormat;

    # Transform all marketplaces to known_marketplaces.json format
    mkKnownMarketplaces = transformers.mkKnownMarketplaces;
  };
}
