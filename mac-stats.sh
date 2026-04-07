#!/bin/bash

# ============================================================
#  mac-stats.sh — Server Performance Statistics (macOS)
#  Usage: bash mac-stats.sh
# ============================================================

# ---- Colour helpers ----------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

divider() {
    echo -e "${CYAN}────────────────────────────────────────────────────────${RESET}"
}

header() {
    echo ""
    divider
    echo -e "  ${BOLD}${YELLOW}$1${RESET}"
    divider
}

# ============================================================
#  SYSTEM OVERVIEW
# ============================================================
header "🖥  SYSTEM OVERVIEW"

OS_NAME=$(sw_vers -productName)
OS_VER=$(sw_vers -productVersion)
BUILD=$(sw_vers -buildVersion)
KERNEL=$(uname -r)
HOSTNAME=$(hostname)
ARCH=$(uname -m)
UPTIME_STR=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}' | xargs)
LOAD_AVG=$(uptime | awk -F'load averages:' '{print $2}' | xargs)

LOGGED_USERS=$(who | awk '{print $1}' | sort -u | tr '\n' ' ')
USER_COUNT=$(who | awk '{print $1}' | sort -u | wc -l | xargs)

echo -e "  ${BOLD}Hostname   :${RESET} $HOSTNAME"
echo -e "  ${BOLD}OS         :${RESET} $OS_NAME $OS_VER (Build $BUILD)"
echo -e "  ${BOLD}Kernel     :${RESET} $KERNEL"
echo -e "  ${BOLD}Architecture:${RESET} $ARCH"
echo -e "  ${BOLD}Uptime     :${RESET} $UPTIME_STR"
echo -e "  ${BOLD}Load Avg   :${RESET} $LOAD_AVG  ${CYAN}(1 / 5 / 15 min)${RESET}"
echo -e "  ${BOLD}Logged In  :${RESET} $USER_COUNT user(s) — $LOGGED_USERS"

# ============================================================
#  CPU USAGE
# ============================================================
header "⚡  CPU USAGE"

CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || sysctl -n hw.model)
CPU_COUNT=$(sysctl -n hw.logicalcpu)
CPU_CORES=$(sysctl -n hw.physicalcpu)

# top -l 2 takes two samples; the second is the accurate live reading
CPU_STATS=$(top -l 2 -n 0 | grep "^CPU usage" | tail -1)
CPU_USER=$(echo "$CPU_STATS"  | awk '{print $3}' | tr -d '%')
CPU_SYS=$(echo "$CPU_STATS"   | awk '{print $5}' | tr -d '%')
CPU_IDLE=$(echo "$CPU_STATS"  | awk '{print $7}' | tr -d '%')
CPU_USED=$(echo "$CPU_USER $CPU_SYS" | awk '{printf "%.1f", $1 + $2}')

echo -e "  ${BOLD}Model      :${RESET} $CPU_MODEL"
echo -e "  ${BOLD}Cores      :${RESET} $CPU_CORES physical / $CPU_COUNT logical"
echo -e "  ${BOLD}Used       :${RESET} ${RED}${CPU_USED}%${RESET}   Idle: ${GREEN}${CPU_IDLE}%${RESET}"

# ============================================================
#  MEMORY USAGE
# ============================================================
header "🧠  MEMORY USAGE"

# Total RAM from sysctl
MEM_TOTAL_B=$(sysctl -n hw.memsize)
MEM_TOTAL_GIB=$(echo "scale=2; $MEM_TOTAL_B / 1073741824" | bc)

# vm_stat gives page counts; page size is typically 4096 bytes on Intel, 16384 on Apple Silicon
PAGE_SIZE=$(vm_stat | grep "page size" | awk '{print $8}')
[ -z "$PAGE_SIZE" ] && PAGE_SIZE=4096

vm_stat_output=$(vm_stat)

pages_free=$(echo "$vm_stat_output"     | awk '/Pages free/      {gsub(/\./,"",$3); print $3}')
pages_active=$(echo "$vm_stat_output"   | awk '/Pages active/    {gsub(/\./,"",$3); print $3}')
pages_inactive=$(echo "$vm_stat_output" | awk '/Pages inactive/  {gsub(/\./,"",$3); print $3}')
pages_wired=$(echo "$vm_stat_output"    | awk '/Pages wired/     {gsub(/\./,"",$4); print $4}')
pages_compressed=$(echo "$vm_stat_output" | awk '/Pages occupied by compressor/ {gsub(/\./,"",$5); print $5}')
[ -z "$pages_compressed" ] && pages_compressed=0

# Used = active + wired + compressed
pages_used=$((pages_active + pages_wired + pages_compressed))
pages_available=$((pages_free + pages_inactive))

MEM_USED_B=$((pages_used      * PAGE_SIZE))
MEM_AVAIL_B=$((pages_available * PAGE_SIZE))
MEM_FREE_B=$((pages_free       * PAGE_SIZE))

MEM_USED_GIB=$(echo  "scale=2; $MEM_USED_B  / 1073741824" | bc)
MEM_AVAIL_GIB=$(echo "scale=2; $MEM_AVAIL_B / 1073741824" | bc)
MEM_FREE_GIB=$(echo  "scale=2; $MEM_FREE_B  / 1073741824" | bc)
MEM_USED_PCT=$(echo  "scale=0; $MEM_USED_B  * 100 / $MEM_TOTAL_B" | bc)
MEM_FREE_PCT=$((100 - MEM_USED_PCT))

echo -e "  ${BOLD}Total      :${RESET} ${MEM_TOTAL_GIB} GiB"
echo -e "  ${BOLD}Used       :${RESET} ${RED}${MEM_USED_GIB} GiB  (${MEM_USED_PCT}%)${RESET}  ${CYAN}(active + wired + compressed)${RESET}"
echo -e "  ${BOLD}Free       :${RESET} ${GREEN}${MEM_FREE_GIB} GiB  (${MEM_FREE_PCT}%)${RESET}"
echo -e "  ${BOLD}Available  :${RESET} ${MEM_AVAIL_GIB} GiB  ${CYAN}(free + inactive/reclaimable)${RESET}"

# Swap
SWAP_USED=$(sysctl -n vm.swapusage 2>/dev/null | awk '{print $6}' | tr -d 'M')
SWAP_TOTAL=$(sysctl -n vm.swapusage 2>/dev/null | awk '{print $3}' | tr -d 'M')
if [ -n "$SWAP_TOTAL" ] && [ "$SWAP_TOTAL" != "0.00" ]; then
    echo -e "  ${BOLD}Swap       :${RESET} ${SWAP_USED}M used of ${SWAP_TOTAL}M"
else
    echo -e "  ${BOLD}Swap       :${RESET} not in use"
fi

# ============================================================
#  DISK USAGE
# ============================================================
header "💾  DISK USAGE"

printf "  ${BOLD}%-20s %8s %8s %8s %5s  %s${RESET}\n" \
    "Filesystem" "Size" "Used" "Avail" "Use%" "Mounted on"
divider

df -h | grep -v '^Filesystem\|^devfs\|^map\|^driverkit' | while IFS= read -r line; do
    PCENT=$(echo "$line" | awk '{print $5}' | tr -d '%')
    COLOR=$GREEN
    [ "$PCENT" -ge 70 ] 2>/dev/null && COLOR=$YELLOW
    [ "$PCENT" -ge 90 ] 2>/dev/null && COLOR=$RED
    SRC=$(echo   "$line" | awk '{print $1}')
    SZ=$(echo    "$line" | awk '{print $2}')
    USED=$(echo  "$line" | awk '{print $3}')
    AVAIL=$(echo "$line" | awk '{print $4}')
    PCT=$(echo   "$line" | awk '{print $5}')
    MNT=$(echo   "$line" | awk '{print $9}')
    printf "  %-20s %8s %8s %8s ${COLOR}%5s${RESET}  %s\n" \
        "$SRC" "$SZ" "$USED" "$AVAIL" "$PCT" "$MNT"
done

# ============================================================
#  TOP 5 PROCESSES — CPU
# ============================================================
header "🔥  TOP 5 PROCESSES BY CPU USAGE"

printf "  ${BOLD}%-8s %-12s %6s %6s  %s${RESET}\n" "PID" "USER" "CPU%" "MEM%" "COMMAND"
divider
ps -eo pid,user,%cpu,%mem,comm -r 2>/dev/null \
    | tail -n +2 \
    | head -5 \
    | awk '{printf "  %-8s %-12s %6s %6s  %s\n", $1, $2, $3, $4, $5}'

# ============================================================
#  TOP 5 PROCESSES — MEMORY
# ============================================================
header "📊  TOP 5 PROCESSES BY MEMORY USAGE"

printf "  ${BOLD}%-8s %-12s %6s %6s  %s${RESET}\n" "PID" "USER" "MEM%" "CPU%" "COMMAND"
divider
ps -eo pid,user,%mem,%cpu,comm -m 2>/dev/null \
    | tail -n +2 \
    | head -5 \
    | awk '{printf "  %-8s %-12s %6s %6s  %s\n", $1, $2, $3, $4, $5}'

# ============================================================
#  NETWORK INTERFACES
# ============================================================
header "🌐  NETWORK INTERFACES"

ifconfig | awk '
/^[a-z]/ { iface=$1; gsub(/:/, "", iface) }
/inet /  { printf "  %-12s  IPv4: %s\n", iface, $2 }
/inet6 / { printf "  %-12s  IPv6: %s\n", iface, $2 }
'

# ============================================================
#  FAILED LOGIN ATTEMPTS
# ============================================================
header "🔒  FAILED LOGIN ATTEMPTS (last 10)"

FAIL_COUNT=$(log show --last 24h --predicate 'eventMessage contains "Failed password"' \
    2>/dev/null | grep -c 'Failed password' || echo 0)

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${BOLD}Failed SSH attempts in last 24h:${RESET} ${RED}$FAIL_COUNT${RESET}"
    echo ""
    log show --last 24h --predicate 'eventMessage contains "Failed password"' \
        2>/dev/null | grep 'Failed password' | tail -10 | awk '{print "  " $0}'
else
    echo -e "  ${GREEN}No failed login attempts found in the last 24 hours.${RESET}"
    echo -e "  ${CYAN}(Run with sudo for full log access)${RESET}"
fi

# ============================================================
#  FOOTER
# ============================================================
echo ""
divider
echo -e "  ${BOLD}Report generated:${RESET} $(date '+%Y-%m-%d %H:%M:%S %Z')"
divider
echo ""
