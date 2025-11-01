#!/usr/bin/env bash
# Test script to check specific module options
# Useful for verifying new modules are correctly integrated

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Module Option Testing ===${NC}"
echo ""

# Function to test an option
check_option() {
    local option="$1"
    local description="$2"

    echo -ne "Checking ${description}... "

    if result=$(nix eval ".#nixosConfigurations.ultimo.config.${option}" 2>&1); then
        echo -e "${GREEN}✓${NC} Value: ${result}"
    else
        echo -e "${YELLOW}✗${NC} Not found (module may not be created yet)"
    fi
}

# Check existing options
echo -e "${YELLOW}Existing Configuration:${NC}"
check_option "modernage.prototype.workstation.enable" "Workstation prototype"
check_option "modernage.desktop.hyprland.enable" "Hyprland desktop"
check_option "modernage.services.tailscale.enable" "Tailscale service"
echo ""

# Check new keyd module (will fail until created)
echo -e "${YELLOW}New Module Options (macOS shortcuts):${NC}"
check_option "modernage.services.keyd.enable" "keyd service"
check_option "services.keyd.enable" "System keyd service"
echo ""

# Check home configuration options
echo -e "${YELLOW}Home Configuration:${NC}"
echo -ne "Checking Hyprland home module... "
if result=$(nix eval '.#homeConfigurations."aodhan@ultimo".config.modernage.hyprland.enable' 2>&1); then
    echo -e "${GREEN}✓${NC} Enabled: ${result}"
else
    echo -e "${RED}✗${NC} Failed to evaluate"
fi

echo -ne "Checking Hyprland keybinding style... "
if result=$(nix eval '.#homeConfigurations."aodhan@ultimo".config.modernage.hyprland.keybindingStyle' 2>&1 | tr -d '"'); then
    if [ "$result" = "null" ]; then
        echo -e "${YELLOW}✓${NC} Not set (will use default)"
    else
        echo -e "${GREEN}✓${NC} Style: ${result}"
    fi
else
    echo -e "${YELLOW}✗${NC} Option not found (needs to be added)"
fi

echo ""
echo -e "${GREEN}=== Option check complete ===${NC}"
echo ""
echo "After adding new modules, run this script to verify they're properly integrated."