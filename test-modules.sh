#!/usr/bin/env bash
# Test script for validating Nix modules during development

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Testing Nix Modules ===${NC}"
echo ""

# Function to run a test and handle errors
run_test() {
    local description="$1"
    local command="$2"

    echo -e "${YELLOW}Testing:${NC} $description"
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $description passed"
    else
        echo -e "${RED}✗${NC} $description failed"
        echo "  Command: $command"
        echo "  Run with --show-trace for details"
        return 1
    fi
    echo ""
}

# Basic flake check
echo -e "${YELLOW}Step 1: Basic Validation${NC}"
run_test "Flake syntax and structure" "nix flake check"

# Build system configuration (without switching)
echo -e "${YELLOW}Step 2: System Build Test${NC}"
run_test "Build ultimo system configuration" "nix build .#nixosConfigurations.ultimo.config.system.build.toplevel --no-link"

# Check specific modules if they exist
echo -e "${YELLOW}Step 3: Module Checks${NC}"

# Check keyd module (will fail gracefully if not created yet)
if [ -f "modules/nixos/services/keyd/default.nix" ]; then
    run_test "keyd module syntax" "nix-instantiate --parse modules/nixos/services/keyd/default.nix"
    run_test "keyd service evaluation" "nix eval .#nixosConfigurations.ultimo.config.modernage.services.keyd.enable"
else
    echo -e "${YELLOW}⚠${NC}  keyd module not created yet"
fi
echo ""

# Check hyprland modifications
run_test "Hyprland module evaluation" "nix eval .#nixosConfigurations.ultimo.config.modernage.desktop.hyprland.enable"

# Home configuration
echo -e "${YELLOW}Step 4: Home Manager Configuration${NC}"
run_test "Build home configuration" "nix build .#homeConfigurations.'aodhan@ultimo'.activationPackage --no-link"

# Format check
echo -e "${YELLOW}Step 5: Code Format${NC}"
if nix fmt -- --check > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} All files properly formatted"
else
    echo -e "${YELLOW}⚠${NC}  Some files need formatting (run 'nix fmt' to fix)"
fi
echo ""

# Optional: Show what would change
if [ "$1" == "--diff" ]; then
    echo -e "${YELLOW}Step 6: Configuration Diff${NC}"
    if [ -f "./result" ]; then
        echo "Showing changes from current system:"
        nix store diff-closures /run/current-system ./result || true
    else
        echo "Build result not found. Run without --no-link to generate diff"
    fi
    echo ""
fi

# Summary
echo -e "${GREEN}=== All essential tests passed! ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Review changes:     nixos-rebuild build --flake .#ultimo && nvd diff /run/current-system ./result"
echo "  2. Test in VM:         nixos-rebuild build-vm --flake .#ultimo"
echo "  3. Apply changes:      sudo nixos-rebuild switch --flake .#ultimo"
echo ""
echo "For detailed errors, run with: nix build .#nixosConfigurations.ultimo.config.system.build.toplevel --show-trace"