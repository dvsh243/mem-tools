#!/bin/bash
# create_swap.sh - Create 8GB swap file if it doesn't exist

SWAP_FILE="/swapfile8g"
SWAP_SIZE="8G"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Swap File Creator ===${NC}"
echo "Target: $SWAP_FILE ($SWAP_SIZE)"

# Check if file already exists
if [[ -f "$SWAP_FILE" ]]; then
    actual_size=$(ls -lh "$SWAP_FILE" | awk '{print $5}')
    echo -e "${YELLOW}⚠ Swap file already exists: $SWAP_FILE ($actual_size)${NC}"
    read -p "Overwrite? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    # Deactivate if active
    if swapon --show | grep -q "$SWAP_FILE"; then
        echo "Deactivating existing swap..."
        sudo swapoff "$SWAP_FILE"
    fi
    sudo rm "$SWAP_FILE"
fi

# Check available disk space
available=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
required=8
if [[ $available -lt $required ]]; then
    echo -e "${RED}✗ Not enough disk space. Available: ${available}G, Required: ${required}G${NC}"
    exit 1
fi

echo "Creating $SWAP_SIZE swap file..."
sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE"
if [[ $? -ne 0 ]]; then
    echo -e "${RED}✗ fallocate failed. Trying dd...${NC}"
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1G count=8 status=progress
fi

sudo chmod 600 "$SWAP_FILE"
echo "Setting up swap area..."
sudo mkswap "$SWAP_FILE"

echo -e "${GREEN}✓ Swap file created: $SWAP_FILE${NC}"
ls -lh "$SWAP_FILE"
echo ""
echo "To activate: sudo swapon $SWAP_FILE"
echo "Or run: ./activate_swap.sh"