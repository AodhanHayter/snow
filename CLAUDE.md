# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "Modern Age" - a comprehensive NixOS/Darwin/Home Manager configuration repository using Nix flakes and the Snowfall Lib framework. It manages system configurations across multiple platforms (NixOS Linux, macOS via nix-darwin) with unified user environments through Home Manager.

## Essential Commands

### Build & Validation
- `nix flake check` - Validate flake syntax and run all checks
- `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel` - Build specific NixOS system
- `nix build .#darwinConfigurations.<hostname>.system` - Build Darwin system  
- `deploy .#<hostname>` - Deploy to remote host using deploy-rs

### Development
- `nix develop` - Enter development shell
- `nix fmt` - Format Nix files

## Architecture & Key Patterns

### Snowfall Lib Framework
- All configurations use Snowfall Lib for consistent organization
- Modules are auto-discovered and follow `modernage` namespace convention
- Custom library functions in `lib/module/default.nix` provide `mkOpt`, `mkBoolOpt`, `enabled`, `disabled` helpers

### Module Structure
- **modules/**: Platform-specific modules (nixos/, darwin/, home/)
- **systems/**: Host-specific configurations organized by architecture
- **homes/**: User-specific Home Manager configurations
- **overlays/**: Custom package overlays for applications

### Configuration Patterns
- All module options use `options.modernage.<category>.<name>` structure
- Boolean options default to `false` unless explicitly enabled
- Use `with lib.modernage;` for accessing custom helper functions
- Import pattern: `{ lib, config, pkgs, ... }:`

## Code Style

- **Formatting**: 2-space indentation, no trailing whitespace
- **Naming**: kebab-case for files/directories, camelCase for Nix attributes
- **Documentation**: `##` for module documentation, `#` for inline comments
- **Options**: Use `mkBoolOpt`, `mkOpt` for consistent option definitions
- **Conditionals**: Use `mkIf` for proper option validation

## Multi-Platform Support

This repository supports:
- **x86_64-linux**: NixOS systems (apollo, atlas, hermes, ultimo)
- **aarch64-darwin**: macOS systems (ahayter-mbp, mac-mini)
- **x86_64-install-iso**: Installation images

Platform-specific modules are organized under respective directories, with Home Manager providing cross-platform user environment consistency.

## Infrastructure Components

- **Kubernetes**: K3s cluster configurations in `k3s/` directory
- **Secrets**: SOPS encryption for sensitive configuration data
- **Storage**: GlusterFS distributed storage system
- **Monitoring**: Prometheus integration for cluster monitoring
- **AI Tools**: MCP server configurations for Claude Code, GitHub, Git integration