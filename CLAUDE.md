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
- **IMPORTANT**: New files must be `git add`ed for Snowfall to discover them

### Directory Structure & Naming

```
systems/<arch>/<hostname>/default.nix     # e.g., systems/x86_64-linux/apollo/
homes/<arch>/<user>@<host>/default.nix    # e.g., homes/x86_64-linux/aodhan@ultimo/
modules/<platform>/<category>/<name>/default.nix  # e.g., modules/home/cli-apps/bat/
overlays/<name>/default.nix               # e.g., overlays/brave/
packages/<name>/default.nix               # e.g., packages/my-pkg/
```

- Module/overlay/package names derived from directory names automatically
- Architecture prefixes: `x86_64-linux`, `aarch64-darwin`, `x86_64-install-iso`

### Snowfall-Injected Function Parameters

All modules, systems, homes, overlays, and packages receive these parameters:

| Parameter | Description |
|-----------|-------------|
| `lib` | Customized instance with flake library access (`lib.modernage.*`) |
| `pkgs` | NixPkgs instance with overlays applied |
| `inputs` | Flake inputs |
| `namespace` | Flake namespace (`"modernage"`) |
| `system` | Architecture string (e.g., `"x86_64-linux"`) |
| `config` | Module system configuration |
| `target` | Snowfall target format |
| `format` | Normalized format name (e.g., `"iso"`) |
| `virtual` | Boolean for nixos-generators targets |
| `systems` | Attribute map of all defined hosts |
| `host` | Hostname (homes only) |
| `channels` | NixPkgs channel instances (overlays only) |

### Custom Library Helpers

Located in `lib/module/default.nix`, accessed via `with lib.modernage;`:

```nix
mkOpt type default description   # Create option with description
mkOpt' type default              # Create option without description
mkBoolOpt default description    # Boolean option shorthand
mkBoolOpt' default               # Boolean option without description
enabled                          # { enable = true; }
disabled                         # { enable = false; }
```

### snowfallorg Namespace

**In systems** - User management:
```nix
snowfallorg.users.<name>.home.enable = true;
```

**In homes** - User context (auto-provided):
```nix
snowfallorg.user.enable   # Boolean
snowfallorg.user.name     # Username string
snowfallorg.user.home     # Home directory path
```

### External Module Integration (flake.nix)

```nix
systems.modules.nixos = [ ... ];   # Applied to all NixOS systems
systems.modules.darwin = [ ... ];  # Applied to all Darwin systems
homes.modules = [ ... ];           # Applied to all homes
```

## Module Template

Standard pattern for home/nixos/darwin modules:

```nix
{ lib, config, ... }:
with lib;
with lib.modernage;
let
  cfg = config.modernage.<category>.<name>;
in
{
  options.modernage.<category>.<name> = {
    enable = mkBoolOpt false "Whether to enable <name>.";
  };

  config = mkIf cfg.enable {
    # Configuration here
  };
}
```

## Overlay Template

Overlays modify or add packages to nixpkgs:

```nix
{ channels, inputs, namespace, ... }:
final: prev:
{
  # Pull from unstable channel
  inherit (channels.unstable) some-package;

  # Override existing package
  some-pkg = prev.some-pkg.override { ... };

  # Add custom package
  my-pkg = final.callPackage ./my-pkg.nix { };
}
```

## Package Template

Custom packages in `packages/<name>/default.nix`:

```nix
{ lib, pkgs, stdenv, inputs, namespace, ... }:
stdenv.mkDerivation {
  pname = "my-package";
  version = "1.0.0";
  src = ./.;
  # ... derivation attributes
}
```

Packages auto-exported as `packages.<name>` and available throughout flake.

## Code Style

- **Formatting**: 2-space indentation, no trailing whitespace
- **Naming**: kebab-case for files/directories, camelCase for Nix attributes
- **Documentation**: `##` for module documentation, `#` for inline comments
- **Options**: Use `mkBoolOpt`, `mkOpt` for consistent option definitions
- **Conditionals**: Use `mkIf` for proper option validation

## Multi-Platform Support

This repository supports:
- **x86_64-linux**: NixOS systems (apollo, atlas, hermes)
- **aarch64-darwin**: macOS systems (ahayter-mbp, mac-mini, maximo)
- **x86_64-install-iso**: Installation images

Platform-specific modules are organized under respective directories, with Home Manager providing cross-platform user environment consistency.

## Infrastructure Components

- **Kubernetes**: K3s cluster configurations in `k3s/` directory
- **Secrets**: SOPS encryption for sensitive configuration data
- **Storage**: GlusterFS distributed storage system
- **Monitoring**: Prometheus integration for cluster monitoring
- **AI Tools**: MCP server configurations for Claude Code, GitHub, Git integration
