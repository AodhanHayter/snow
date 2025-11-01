#!/usr/bin/env bash
# Practical build test for module development
# Focuses on ensuring new modules build correctly

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== NixOS Module Build Test ===${NC}"
echo ""

# Quick syntax check for a specific file if provided
if [ -n "$1" ]; then
    echo -e "${YELLOW}Checking syntax of $1...${NC}"
    if nix-instantiate --parse "$1" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Syntax valid"
    else
        echo -e "${RED}✗${NC} Syntax error in $1"
        nix-instantiate --parse "$1"
        exit 1
    fi
    echo ""
fi

# Test the build
echo -e "${YELLOW}Testing ultimo system build...${NC}"
echo "This will verify all modules compile correctly."
echo ""

if nix build '.#nixosConfigurations.ultimo.config.system.build.toplevel' --dry-run &> /dev/null; then
    echo -e "${GREEN}✓${NC} Configuration builds successfully!"
    echo ""

    # Show what would be built
    echo -e "${BLUE}Derivations that would be built:${NC}"
    nix build '.#nixosConfigurations.ultimo.config.system.build.toplevel' --dry-run 2>&1 | grep "will be built:" -A 20 | head -25
else
    echo -e "${RED}✗${NC} Build failed!"
    echo ""
    echo "Run with --show-trace for details:"
    echo "  nix build '.#nixosConfigurations.ultimo.config.system.build.toplevel' --show-trace"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Build test passed! ===${NC}"
echo ""
echo "To actually build and see changes:"
echo -e "  ${BLUE}nixos-rebuild build --flake .#ultimo${NC}"
echo ""
echo "To apply changes to the system:"
echo -e "  ${BLUE}sudo nixos-rebuild switch --flake .#ultimo${NC}"