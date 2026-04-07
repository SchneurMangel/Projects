#!/bin/bash

# ============================================================
#  server-stats.sh — Server Performance Statistics
#  Usage: bash server-stats.sh
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

# OS / Distro
if [ -f /etc/os-release ]; then
    OS_NAME=$(grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '"')
else
    OS_NAME=$(uname -s)
fi
KERNEL=$(uname -r)
HOSTNAME=$(hostname)
ARCH=$(uname -m)

echo -e "  ${BOLD}Hostname   :${RESET} $HOSTNAME"
echo -e "  ${BOLD}OS         :${RESET} $OS_NAME"
echo -e "  ${BOLD}Kernel     :${RESET} $KERNEL"
echo -e "  ${BOLD}Architecture:${RESET} $ARCH"

# Uptime & load average
UPTIME_STR=$(uptime -p 2>/dev/null || uptime)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
echo -e "  ${BOLD}Uptime     :${RESET} $UPTIME_STR"
echo -e "  ${BOLD}Load Avg   :${RESET} $LOAD_AVG  ${CYAN}(1 / 5 / 15 min)${RESET}"

# Logged-in users
LOGGED_USERS=$(who | awk '{print $1}' | sort -u | tr '\n' ' ')
USER_COUNT=$(who | awk '{print $1}' | sort -u | wc -l | xargs)
echo -e "  ${BOLD}Logged In  :${RESET} $USER_COUNT user(s) — ${LOGGED_USERS}"

# ============================================================
#  CPU USAGE
# ============================================================
header "⚡  CPU USAGE"

CPU_COUNT=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo)
CPU_MODEL=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)

# Idle % from /proc/stat — reliable across distros
read CPU_USER CPU_NICE CPU_SYS CPU_IDLE CPU_IOWAIT CPU_IRQ CPU_SOFTIRQ _ \
    < <(grep '^cpu ' /proc/stat | awk '{print $2,$3,$4,$5,$6,$7,$8}')

TOTAL1=$((CPU_USER + CPU_NICE + CPU_SYS + CPU_IDLE + CPU_IOWAIT + CPU_IRQ + CPU_SOFTIRQ))
sleep 0.5
read CPU_USER2 CPU_NICE2 CPU_SYS2 CPU_IDLE2 CPU_IOWAIT2 CPU_IRQ2 CPU_SOFTIRQ2 _ \
    < <(grep '^cpu ' /proc/stat | awk '{print $2,$3,$4,$5,$6,$7,$8}')

TOTAL2=$((CPU_USER2 + CPU_NICE2 + CPU_SYS2 + CPU_IDLE2 + CPU_IOWAIT2 + CPU_IRQ2 + CPU_SOFTIRQ2))
DIFF_IDLE=$((CPU_IDLE2 - CPU_IDLE))
DIFF_TOTAL=$((TOTAL2 - TOTAL1))

if [ "$DIFF_TOTAL" -gt 0 ]; then
    CPU_USED_PCT=$(( (DIFF_TOTAL - DIFF_IDLE) * 100 / DIFF_TOTAL ))
    CPU_IDLE_PCT=$(( DIFF_IDLE * 100 / DIFF_TOTAL ))
else
    CPU_USED_PCT=0
    CPU_IDLE_PCT=100
fi

echo -e "  ${BOLD}Model      :${RESET} $CPU_MODEL"
echo -e "  ${BOLD}Cores      :${RESET} $CPU_COUNT"
echo -e "  ${BOLD}Used       :${RESET} ${RED}${CPU_USED_PCT}%${RESET}   Idle: ${GREEN}${CPU_IDLE_PCT}%${RESET}"

# ============================================================
#  MEMORY USAGE
# ============================================================
header "🧠  MEMORY USAGE"

MEM_LINE=$(free -b | grep '^Mem:')
MEM_TOTAL_B=$(echo "$MEM_LINE" | awk '{print $2}')
MEM_USED_B=$(echo  "$MEM_LINE" | awk '{print $3}')
MEM_FREE_B=$(echo  "$MEM_LINE" | awk '{print $4}')
MEM_AVAIL_B=$(echo "$MEM_LINE" | awk '{print $7}')

# Convert to MiB / GiB
to_human() {
    local bytes=$1
    if   [ "$bytes" -ge $((1024*1024*1024)) ]; then
        printf "%.2f GiB" "$(echo "scale=2; $bytes / 1073741824" | bc)"
    else
        printf "%d MiB" $(( bytes / 1048576 ))
    fi
}

MEM_TOTAL_H=$(to_human "$MEM_TOTAL_B")
MEM_USED_H=$(to_human  "$MEM_USED_B")
MEM_FREE_H=$(to_human  "$MEM_FREE_B")
MEM_AVAIL_H=$(to_human "$MEM_AVAIL_B")
MEM_USED_PCT=$(( MEM_USED_B * 100 / MEM_TOTAL_B ))
MEM_FREE_PCT=$(( 100 - MEM_USED_PCT ))

echo -e "  ${BOLD}Total      :${RESET} $MEM_TOTAL_H"
echo -e "  ${BOLD}Used       :${RESET} ${RED}$MEM_USED_H  (${MEM_USED_PCT}%)${RESET}"
echo -e "  ${BOLD}Free       :${RESET} ${GREEN}$MEM_FREE_H  (${MEM_FREE_PCT}%)${RESET}"
echo -e "  ${BOLD}Available  :${RESET} $MEM_AVAIL_H  ${CYAN}(includes reclaimable cache)${RESET}"

# Swap
SWAP_LINE=$(free -b | grep '^Swap:')
SWAP_TOTAL_B=$(echo "$SWAP_LINE" | awk '{print $2}')
if [ "$SWAP_TOTAL_B" -gt 0 ]; then
    SWAP_USED_B=$(echo "$SWAP_LINE" | awk '{print $3}')
    SWAP_FREE_B=$(echo "$SWAP_LINE" | awk '{print $4}')
    SWAP_USED_PCT=$(( SWAP_USED_B * 100 / SWAP_TOTAL_B ))
    echo -e "  ${BOLD}Swap Total :${RESET} $(to_human "$SWAP_TOTAL_B")"
    echo -e "  ${BOLD}Swap Used  :${RESET} $(to_human "$SWAP_USED_B")  (${SWAP_USED_PCT}%)"
else
    echo -e "  ${BOLD}Swap       :${RESET} not configured"
fi

# ============================================================
#  DISK USAGE
# ============================================================
header "💾  DISK USAGE"

printf "  ${BOLD}%-20s %8s %8s %8s %5s  %s${RESET}\n" \
    "Filesystem" "Size" "Used" "Avail" "Use%" "Mounted on"
divider

df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
    | grep -v '^Filesystem' \
    | grep -v '^tmpfs\|^udev\|^devtmpfs\|^overlay\|^none' \
    | while IFS= read -r line; do
    PCENT=$(echo "$line" | awk '{print $5}' | tr -d '%')
    COLOR=$GREEN
    [ "$PCENT" -ge 70 ] 2>/dev/null && COLOR=$YELLOW
    [ "$PCENT" -ge 90 ] 2>/dev/null && COLOR=$RED
    SRC=$(echo "$line" | awk '{print $1}')
    SZ=$(echo  "$line" | awk '{print $2}')
    USED=$(echo "$line" | awk '{print $3}')
    AVAIL=$(echo "$line" | awk '{print $4}')
    PCT=$(echo "$line" | awk '{print $5}')
    MNT=$(echo "$line" | awk '{print $6}')
    printf "  %-20s %8s %8s %8s ${COLOR}%5s${RESET}  %s\n" \
        "$SRC" "$SZ" "$USED" "$AVAIL" "$PCT" "$MNT"
done

# ============================================================
#  TOP 5 PROCESSES — CPU
# ============================================================
header "🔥  TOP 5 PROCESSES BY CPU USAGE"

printf "  ${BOLD}%-8s %-12s %6s %6s  %s${RESET}\n" "PID" "USER" "CPU%" "MEM%" "COMMAND"
divider
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu 2>/dev/null \
    | tail -n +2 \
    | head -5 \
    | awk '{printf "  %-8s %-12s %6s %6s  %s\n", $1, $2, $3, $4, $5}'

# ============================================================
#  TOP 5 PROCESSES — MEMORY
# ============================================================
header "📊  TOP 5 PROCESSES BY MEMORY USAGE"

printf "  ${BOLD}%-8s %-12s %6s %6s  %s${RESET}\n" "PID" "USER" "MEM%" "CPU%" "COMMAND"
divider
ps -eo pid,user,%mem,%cpu,comm --sort=-%mem 2>/dev/null \
    | tail -n +2 \
    | head -5 \
    | awk '{printf "  %-8s %-12s %6s %6s  %s\n", $1, $2, $3, $4, $5}'

# ============================================================
#  NETWORK INTERFACES
# ============================================================
header "🌐  NETWORK INTERFACES"

ip -brief addr show 2>/dev/null | while read -r iface state addrs; do
    printf "  %-12s  %-10s  %s\n" "$iface" "$state" "$addrs"
done

# ============================================================
#  FAILED LOGIN ATTEMPTS  (last 10, requires auth.log / secure)
# ============================================================
header "🔒  FAILED LOGIN ATTEMPTS (last 10)"

FAIL_LOG=""
for log_file in /var/log/auth.log /var/log/secure; do
    if [ -r "$log_file" ]; then
        FAIL_LOG=$log_file
        break
    fi
done

if [ -n "$FAIL_LOG" ]; then
    FAIL_COUNT=$(grep -c 'Failed password' "$FAIL_LOG" 2>/dev/null || echo 0)
    echo -e "  ${BOLD}Total failed attempts in $FAIL_LOG:${RESET} ${RED}$FAIL_COUNT${RESET}"
    echo ""
    grep 'Failed password' "$FAIL_LOG" 2>/dev/null \
        | tail -10 \
        | awk '{print "  " $0}'
else
    echo -e "  ${YELLOW}Auth log not readable (try running as root for this section).${RESET}"
fi

# ============================================================
#  FOOTER
# ============================================================
echo ""
divider
echo -e "  ${BOLD}Report generated:${RESET} $(date '+%Y-%m-%d %H:%M:%S %Z')"
divider
echo ""
