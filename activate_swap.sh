#!/bin/bash
# activate_swap.sh - Activate the 8GB swap file

SWAP_FILE="/swapfile8g"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Swap Activator ===${NC}"

# Check if file exists
if [[ ! -f "$SWAP_FILE" ]]; then
    echo -e "${RED}✗ Swap file not found: $SWAP_FILE${NC}"
    echo "Run ./create_swap.sh first"
    exit 1
fi

# Check if already active
if swapon --show | grep -q "$SWAP_FILE"; then
    echo -e "${YELLOW}⚠ Swap already active: $SWAP_FILE${NC}"
    swapon --show | grep "$SWAP_FILE"
    exit 0
fi

echo "Activating $SWAP_FILE..."
sudo swapon "$SWAP_FILE"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Swap activated${NC}"
    echo ""
    echo "Current swap status:"
    free -h
    echo ""
    swapon --show
else
    echo -e "${RED}✗ Failed to activate swap${NC}"
    exit 1
fi