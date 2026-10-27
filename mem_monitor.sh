#!/bin/bash
# mem_monitor.sh - Minimal two-line memory/swap monitor (no flicker)

INTERVAL="${1:-0.5}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Hide cursor, save position
tput civis
tput sc
trap 'tput cnorm; tput rc; echo; exit 0' INT TERM

while true; do
    # Read all values at once
    read MEM_TOTAL_KB MEM_AVAIL_KB SWAP_TOTAL_KB SWAP_FREE_KB <<< $(
        awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} /^SwapTotal:/{st=$2} /^SwapFree:/{sf=$2} END{print t, a, st, sf}' /proc/meminfo
    )
    
    MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
    SWAP_USED_KB=$((SWAP_TOTAL_KB - SWAP_FREE_KB))
    
    MEM_PCT=$(( MEM_USED_KB * 100 / MEM_TOTAL_KB ))
    SWAP_PCT=$(( SWAP_TOTAL_KB > 0 ? SWAP_USED_KB * 100 / SWAP_TOTAL_KB : 0 ))
    
    # Integer math for GB (tenths)
    MEM_USED_GB=$(( MEM_USED_KB * 10 / 1024 / 1024 ))
    MEM_TOTAL_GB=$(( MEM_TOTAL_KB * 10 / 1024 / 1024 ))
    SWAP_USED_GB=$(( SWAP_USED_KB * 10 / 1024 / 1024 ))
    SWAP_TOTAL_GB=$(( SWAP_TOTAL_KB * 10 / 1024 / 1024 ))
    
    # Color
    if [[ $MEM_PCT -gt 85 ]]; then MC=$RED; elif [[ $MEM_PCT -gt 70 ]]; then MC=$YELLOW; else MC=$GREEN; fi
    if [[ $SWAP_PCT -gt 50 ]]; then SC=$RED; elif [[ $SWAP_PCT -gt 20 ]]; then SC=$YELLOW; else SC=$GREEN; fi
    
    # Restore cursor position, write two lines, clear to end of line
    tput rc
    printf "${BLUE}RAM:${NC}  ${MC}%3d%%${NC} (%2d.%1d/%2d.%1d GB)\033[K\n" \
        "$MEM_PCT" \
        $((MEM_USED_GB/10)) $((MEM_USED_GB%10)) \
        $((MEM_TOTAL_GB/10)) $((MEM_TOTAL_GB%10))
    printf "${BLUE}SWAP:${NC} ${SC}%3d%%${NC} (%2d.%1d/%2d.%1d GB)\033[K" \
        "$SWAP_PCT" \
        $((SWAP_USED_GB/10)) $((SWAP_USED_GB%10)) \
        $((SWAP_TOTAL_GB/10)) $((SWAP_TOTAL_GB%10))
    
    sleep "$INTERVAL"
done