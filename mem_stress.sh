#!/bin/bash
# mem_stress.sh - Bash wrapper for Python memory stress test
# Default: 5 GB gradual over 10 seconds. Usage: ./mem_stress.sh [GB] [gradual|instant|thrash] [duration_sec]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/mem_stress.py"

# Defaults
GB="${1:-5}"
MODE="${2:-gradual}"
DURATION="${3:-10}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check Python script exists
if [[ ! -f "$PY_SCRIPT" ]]; then
    echo -e "${RED}✗ Python script not found: $PY_SCRIPT${NC}"
    exit 1
fi

# Validate GB argument
if ! [[ "$GB" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo -e "${RED}✗ Invalid GB value: $GB${NC}"
    echo "Usage: $0 [GB] [gradual|instant|thrash] [duration_sec]"
    echo "  Default: $0 5 gradual 10"
    exit 1
fi

# Validate mode
if [[ "$MODE" != "gradual" && "$MODE" != "instant" && "$MODE" != "thrash" ]]; then
    echo -e "${RED}✗ Invalid mode: $MODE (use 'gradual', 'instant', or 'thrash')${NC}"
    exit 1
fi

# Show system info
echo -e "${BLUE}=== Memory Stress Test ===${NC}"
echo -e "Mode:     ${YELLOW}$MODE${NC}"
echo -e "Target:   ${YELLOW}${GB} GB${NC}"
[[ "$MODE" != "instant" ]] && echo -e "Duration: ${YELLOW}${DURATION}s${NC}"
echo ""

# Show available RAM
avail_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
avail_gb=$(echo "scale=2; $avail_kb / 1024 / 1024" | bc 2>/dev/null || echo "~3.6")
echo -e "RAM avail: ${GREEN}${avail_gb} GB${NC}"

# Warn if exceeding RAM
if (( $(echo "$GB > $avail_gb" | bc -l 2>/dev/null || echo 1) )); then
    swap_needed=$(echo "scale=1; $GB - $avail_gb" | bc 2>/dev/null || echo "?")
    echo -e "${YELLOW}⚠ Will force ~${swap_needed} GB into swap${NC}"
fi

echo ""
echo -e "${BLUE}Starting... Press Ctrl+C to stop${NC}"
echo ""

# Run the Python script
if [[ "$MODE" == "gradual" ]]; then
    python3 "$PY_SCRIPT" gradual "$GB" -t "$DURATION"
elif [[ "$MODE" == "instant" ]]; then
    python3 "$PY_SCRIPT" instant "$GB"
else
    python3 "$PY_SCRIPT" thrash "$GB" -t "$DURATION"
fi