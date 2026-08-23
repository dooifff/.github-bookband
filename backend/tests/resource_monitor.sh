#!/bin/bash

# StudioBook Resource Monitor
# Monitors server resources during testing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudioBook Resource Monitor                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to get CPU usage
get_cpu_usage() {
    if command -v mpstat &> /dev/null; then
        mpstat 1 1 | tail -1 | awk '{print $3}'
    elif [ -f /proc/stat ]; then
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    else
        echo "N/A"
    fi
}

# Function to get memory usage
get_memory_usage() {
    if command -v free &> /dev/null; then
        free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
    elif [ -f /proc/meminfo ]; then
        awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {printf "%.1f", (total-avail)/total*100}' /proc/meminfo
    else
        echo "N/A"
    fi
}

# Function to get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $5}' | tr -d '%'
}

# Function to get network connections
get_connections() {
    if command -v netstat &> /dev/null; then
        netstat -an | grep :8000 | grep ESTABLISHED | wc -l
    else
        echo "N/A"
    fi
}

# Function to get PHP-FPM processes
get_php_processes() {
    if command -v pgrep &> /dev/null; then
        pgrep -f php-fpm | wc -l
    else
        echo "N/A"
    fi
}

# Main monitoring loop
echo -e "${YELLOW}Starting resource monitoring (Ctrl+C to stop)...${NC}"
echo ""
echo -e "${BLUE}Timestamp          CPU%    Memory%  Disk%   Connections  PHP Processes${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────────${NC}"

while true; do
    CPU=$(get_cpu_usage)
    MEMORY=$(get_memory_usage)
    DISK=$(get_disk_usage)
    CONNECTIONS=$(get_connections)
    PHP_PROCS=$(get_php_processes)
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Color code based on thresholds
    CPU_COLOR=$GREEN
    MEMORY_COLOR=$GREEN
    DISK_COLOR=$GREEN
    
    if (( $(echo "$CPU > 80" | bc -l 2>/dev/null || echo 0) )); then
        CPU_COLOR=$RED
    elif (( $(echo "$CPU > 60" | bc -l 2>/dev/null || echo 0) )); then
        CPU_COLOR=$YELLOW
    fi
    
    if (( $(echo "$MEMORY > 80" | bc -l 2>/dev/null || echo 0) )); then
        MEMORY_COLOR=$RED
    elif (( $(echo "$MEMORY > 60" | bc -l 2>/dev/null || echo 0) )); then
        MEMORY_COLOR=$YELLOW
    fi
    
    if (( DISK > 80 )); then
        DISK_COLOR=$RED
    elif (( DISK > 60 )); then
        DISK_COLOR=$YELLOW
    fi
    
    printf "%-18s ${CPU_COLOR}%6s${NC}  ${MEMORY_COLOR}%6s${NC}  ${DISK_COLOR}%5s${NC}   %-10s %-10s\n" \
        "$TIMESTAMP" "${CPU}%" "${MEMORY}%" "${DISK}%" "$CONNECTIONS" "$PHP_PROCS"
    
    sleep 2
done
