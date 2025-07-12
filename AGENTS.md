# AGENTS.md - NixOS/Darwin Configuration Repository

## Build/Test Commands
- `nix flake check` - Validate flake syntax and run all checks
- `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel` - Build specific system
- `nix build .#darwinConfigurations.<hostname>.system` - Build Darwin system
- `deploy .#<hostname>` - Deploy to remote host using deploy-rs

## Code Style Guidelines
- **Language**: Nix expressions using Snowfall Lib framework
- **Imports**: Use `{ lib, config, pkgs, ... }:` parameter pattern
- **Formatting**: 2-space indentation, no trailing whitespace
- **Naming**: Use kebab-case for file/directory names, camelCase for Nix attributes
- **Module Structure**: Follow `options.modernage.<category>.<name>` pattern
- **Types**: Use `mkBoolOpt`, `mkOpt` from Snowfall Lib for options
- **Comments**: Use `##` for documentation, `#` for inline comments
- **Error Handling**: Use `mkIf` conditions and proper option validation

## Repository Structure
- `modules/` - NixOS/Darwin/Home Manager modules organized by platform
- `systems/` - Host-specific configurations
- `overlays/` - Package overlays
- `homes/` - Home Manager configurations
- `lib/` - Custom library functions
- `secrets/` - SOPS encrypted secrets

## Key Patterns
- All modules use `modernage` namespace
- Enable options default to `false`
- Use `with lib.modernage;` for custom functions