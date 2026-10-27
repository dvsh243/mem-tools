#!/bin/bash
# mem_monitor.sh - Pretty real-time memory/swap monitor

INTERVAL="${1:-0.5}"  # Default 0.5s, can pass as argument

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Unicode chars
BAR_FULL="█"
BAR_EMPTY="░"
ARROW_UP="▲"
ARROW_DOWN="▼"

clear_screen() {
    printf '\033[2J\033[H'
}

draw_bar() {
    local pct=$1
    local width=30
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local color=$2
    
    printf "${color}"
    printf "%${filled}s" | tr ' ' "$BAR_FULL"
    printf "${DIM}"
    printf "%${empty}s" | tr ' ' "$BAR_EMPTY"
    printf "${NC}"
}

format_gb() {
    local kb=$1
    echo "scale=2; $kb / 1024 / 1024" | bc 2>/dev/null || echo "0"
}

get_meminfo() {
    # Parse /proc/meminfo once
    local meminfo=$(cat /proc/meminfo)
    
    MEM_TOTAL_KB=$(echo "$meminfo" | grep '^MemTotal:' | awk '{print $2}')
    MEM_AVAIL_KB=$(echo "$meminfo" | grep '^MemAvailable:' | awk '{print $2}')
    MEM_FREE_KB=$(echo "$meminfo" | grep '^MemFree:' | awk '{print $2}')
    SWAP_TOTAL_KB=$(echo "$meminfo" | grep '^SwapTotal:' | awk '{print $2}')
    SWAP_FREE_KB=$(echo "$meminfo" | grep '^SwapFree:' | awk '{print $2}')
    BUFFERS_KB=$(echo "$meminfo" | grep '^Buffers:' | awk '{print $2}')
    CACHED_KB=$(echo "$meminfo" | grep '^Cached:' | awk '{print $2}')
    SWAP_CACHED_KB=$(echo "$meminfo" | grep '^SwapCached:' | awk '{print $2}')
    
    # Calculate
    MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
    SWAP_USED_KB=$((SWAP_TOTAL_KB - SWAP_FREE_KB))
    
    MEM_PCT=$(( MEM_USED_KB * 100 / MEM_TOTAL_KB ))
    SWAP_PCT=$(( SWAP_TOTAL_KB > 0 ? SWAP_USED_KB * 100 / SWAP_TOTAL_KB : 0 ))
    
    MEM_TOTAL_GB=$(format_gb $MEM_TOTAL_KB)
    MEM_USED_GB=$(format_gb $MEM_USED_KB)
    MEM_AVAIL_GB=$(format_gb $MEM_AVAIL_KB)
    SWAP_TOTAL_GB=$(format_gb $SWAP_TOTAL_KB)
    SWAP_USED_GB=$(format_gb $SWAP_USED_KB)
    SWAP_FREE_GB=$(format_gb $SWAP_FREE_KB)
}

get_swap_devices() {
    swapon --show=NAME,SIZE,USED,PRIO --noheadings --bytes 2>/dev/null | while read name size used prio; do
        size_gb=$(echo "scale=2; $size / 1024 / 1024 / 1024" | bc 2>/dev/null)
        used_gb=$(echo "scale=2; $used / 1024 / 1024 / 1024" | bc 2>/dev/null)
        used_pct=$(( size > 0 ? used * 100 / size : 0 ))
        printf "  ${CYAN}%-20s${NC} %6s GB / %6s GB  (%3d%%)  prio: %s\n" "$name" "$used_gb" "$size_gb" "$used_pct" "$prio"
    done
}

print_header() {
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}MEMORY & SWAP MONITOR${NC}  ${DIM}Interval: ${INTERVAL}s | Press Ctrl+C to exit${NC}  ${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_memory() {
    local mem_color=$GREEN
    [[ $MEM_PCT -gt 70 ]] && mem_color=$YELLOW
    [[ $MEM_PCT -gt 90 ]] && mem_color=$RED
    
    local swap_color=$GREEN
    [[ $SWAP_PCT -gt 50 ]] && swap_color=$YELLOW
    [[ $SWAP_PCT -gt 80 ]] && swap_color=$RED
    
    echo -e "${BOLD}┌─ PHYSICAL MEMORY ────────────────────────────────────────────────┐${NC}"
    printf "  ${BOLD}Total:${NC} %8s GB  ${BOLD}Used:${NC} %8s GB  ${BOLD}Avail:${NC} %8s GB\n" "$MEM_TOTAL_GB" "$MEM_USED_GB" "$MEM_AVAIL_GB"
    printf "  ${BOLD}Usage:${NC} %3d%% " "$MEM_PCT"
    draw_bar $MEM_PCT $mem_color
    printf " ${mem_color}%3d%%${NC}\n" "$MEM_PCT"
    echo -e "${BOLD}└──────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

print_swap() {
    local swap_color=$GREEN
    [[ $SWAP_PCT -gt 50 ]] && swap_color=$YELLOW
    [[ $SWAP_PCT -gt 80 ]] && swap_color=$RED
    
    echo -e "${BOLD}┌─ SWAP ───────────────────────────────────────────────────────────┐${NC}"
    printf "  ${BOLD}Total:${NC} %8s GB  ${BOLD}Used:${NC} %8s GB  ${BOLD}Free:${NC} %8s GB\n" "$SWAP_TOTAL_GB" "$SWAP_USED_GB" "$SWAP_FREE_GB"
    printf "  ${BOLD}Usage:${NC} %3d%% " "$SWAP_PCT"
    draw_bar $SWAP_PCT $swap_color
    printf " ${swap_color}%3d%%${NC}\n" "$SWAP_PCT"
    
    if [[ $SWAP_TOTAL_KB -gt 0 ]]; then
        echo -e "  ${BOLD}Devices:${NC}"
        get_swap_devices
    fi
    echo -e "${BOLD}└──────────────────────────────────────────────────────────────────┘${NC}"
}

print_details() {
    echo -e "${BOLD}┌─ DETAILS ────────────────────────────────────────────────────────┐${NC}"
    printf "  ${DIM}Buffers:${NC} %8s GB  ${DIM}Cached:${NC} %8s GB  ${DIM}SwapCached:${NC} %8s GB\n" \
        "$(format_gb $BUFFERS_KB)" "$(format_gb $CACHED_KB)" "$(format_gb $SWAP_CACHED_KB)"
    echo -e "${BOLD}└──────────────────────────────────────────────────────────────────┘${NC}"
}

# Trap Ctrl+C
trap 'clear_screen; echo -e "\n${GREEN}Monitor stopped.${NC}"; exit 0' INT TERM

# Main loop
echo -e "\n${CYAN}Starting monitor (interval: ${INTERVAL}s)...${NC}"
sleep 0.5

while true; do
    get_meminfo
    clear_screen
    print_header
    print_memory
    print_swap
    print_details
    sleep "$INTERVAL"
done