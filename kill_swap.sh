#!/bin/bash
# kill_swap.sh - Deactivate and completely remove the 8GB swap file

SWAP_FILE="/swapfile8g"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Swap Killer ===${NC}"
echo "Target: $SWAP_FILE"

# Check if file exists
if [[ ! -f "$SWAP_FILE" ]]; then
    echo -e "${YELLOW}⚠ Swap file doesn't exist: $SWAP_FILE${NC}"
    echo "Nothing to do."
    exit 0
fi

# Show current status
echo "Current status:"
ls -lh "$SWAP_FILE"
if swapon --show | grep -q "$SWAP_FILE"; then
    echo -e "${YELLOW}  Status: ACTIVE${NC}"
else
    echo -e "${GREEN}  Status: INACTIVE${NC}"
fi

echo ""
read -p "Deactivate and PERMANENTLY DELETE $SWAP_FILE (free ~8GB)? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Deactivate if active
if swapon --show | grep -q "$SWAP_FILE"; then
    echo "Deactivating swap..."
    sudo swapoff "$SWAP_FILE"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ Failed to deactivate swap${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Swap deactivated${NC}"
fi

# Remove file
echo "Removing file..."
sudo rm "$SWAP_FILE"
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Swap file deleted${NC}"
    echo -e "${GREEN}✓ ~8GB storage freed${NC}"
else
    echo -e "${RED}✗ Failed to delete file${NC}"
    exit 1
fi

echo ""
echo "Current swap status:"
free -h
swapon --show