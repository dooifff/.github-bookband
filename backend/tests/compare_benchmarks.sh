#!/bin/bash

# ============================================
# StudioBook Benchmark Comparison Tool
# ============================================
# Compare current benchmarks with historical data
# Usage: ./compare_benchmarks.sh <current_report> [previous_report]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CURRENT_REPORT="${1:-}"
PREVIOUS_REPORT="${2:-}"

if [ -z "$CURRENT_REPORT" ]; then
    echo "Usage: $0 <current_report> [previous_report]"
    echo ""
    echo "Examples:"
    echo "  $0 benchmark-report-20240115.md"
    echo "  $0 benchmark-report-20240115.md benchmark-report-20240114.md"
    exit 1
fi

if [ ! -f "$CURRENT_REPORT" ]; then
    echo -e "${RED}Error: Current report not found: $CURRENT_REPORT${NC}"
    exit 1
fi

# ============================================
# Helper Functions
# ============================================

extract_metric() {
    local file=$1
    local metric=$2
    grep -E "\| $metric \|.*\|.*\|" "$file" 2>/dev/null | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' | head -1
}

extract_value() {
    local file=$1
    local metric=$2
    grep -E "\| $metric \|.*\|.*\|" "$file" 2>/dev/null | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | head -1
}

compare_values() {
    local current=$1
    local previous=$2
    local metric=$3
    local lower_is_better=$4
    
    # Remove non-numeric characters for comparison
    current=$(echo "$current" | sed 's/[^0-9.]//g')
    previous=$(echo "$previous" | sed 's/[^0-9.]//g')
    
    if [ -z "$current" ] || [ -z "$previous" ]; then
        echo "N/A"
        return
    fi
    
    local diff=$(echo "scale=2; $current - $previous" | bc)
    local percent=$(echo "scale=2; ($diff / $previous) * 100" | bc 2>/dev/null || echo "0")
    
    if [ "$lower_is_better" = "true" ]; then
        if (( $(echo "$current < $previous" | bc -l) )); then
            echo -e "${GREEN}↓ ${percent}% improved${NC}"
        elif (( $(echo "$current > $previous" | bc -l) )); then
            echo -e "${RED}↑ ${percent}% worse${NC}"
        else
            echo -e "${YELLOW}→ No change${NC}"
        fi
    else
        if (( $(echo "$current > $previous" | bc -l) )); then
            echo -e "${GREEN}↑ ${percent}% improved${NC}"
        elif (( $(echo "$current < $previous" | bc -l) )); then
            echo -e "${RED}↓ ${percent}% worse${NC}"
        else
            echo -e "${YELLOW}→ No change${NC}"
        fi
    fi
}

# ============================================
# Main Comparison
# ============================================

echo ""
echo "============================================"
echo "   Benchmark Comparison Report"
echo "============================================"
echo ""
echo "Current:  $CURRENT_REPORT"
if [ -n "$PREVIOUS_REPORT" ] && [ -f "$PREVIOUS_REPORT" ]; then
    echo "Previous: $PREVIOUS_REPORT"
else
    echo "Previous: N/A (first run or file not found)"
fi
echo ""

# Extract and display current metrics
echo -e "${BLUE}Current Benchmark Results:${NC}"
echo ""

if grep -q "Health Check P95" "$CURRENT_REPORT"; then
    HEALTH_P95=$(extract_value "$CURRENT_REPORT" "Health Check P95")
    HEALTH_RPS=$(extract_value "$CURRENT_REPORT" "Health Check RPS")
    STUDIOS_P95=$(extract_value "$CURRENT_REPORT" "Studios P95")
    SEARCH_P95=$(extract_value "$CURRENT_REPORT" "Search P95")
    ERROR_RATE=$(extract_value "$CURRENT_REPORT" "Concurrent Error Rate")
    
    echo "  Health Check P95:  ${HEALTH_P95:-N/A}"
    echo "  Health Check RPS:  ${HEALTH_RPS:-N/A}"
    echo "  Studios P95:       ${STUDIOS_P95:-N/A}"
    echo "  Search P95:        ${SEARCH_P95:-N/A}"
    echo "  Error Rate:        ${ERROR_RATE:-N/A}"
fi

echo ""

# Compare with previous if available
if [ -n "$PREVIOUS_REPORT" ] && [ -f "$PREVIOUS_REPORT" ]; then
    echo -e "${BLUE}Comparison with Previous Run:${NC}"
    echo ""
    
    if grep -q "Health Check P95" "$CURRENT_REPORT" && grep -q "Health Check P95" "$PREVIOUS_REPORT"; then
        CUR_H_P95=$(extract_value "$CURRENT_REPORT" "Health Check P95")
        PREV_H_P95=$(extract_value "$PREVIOUS_REPORT" "Health Check P95")
        echo -e "  Health Check P95: $(compare_values "$CUR_H_P95" "$PREV_H_P95" "Health P95" "true")"
        
        CUR_H_RPS=$(extract_value "$CURRENT_REPORT" "Health Check RPS")
        PREV_H_RPS=$(extract_value "$PREVIOUS_REPORT" "Health Check RPS")
        echo -e "  Health Check RPS: $(compare_values "$CUR_H_RPS" "$PREV_H_RPS" "Health RPS" "false")"
        
        CUR_S_P95=$(extract_value "$CURRENT_REPORT" "Studios P95")
        PREV_S_P95=$(extract_value "$PREVIOUS_REPORT" "Studios P95")
        echo -e "  Studios P95:      $(compare_values "$CUR_S_P95" "$PREV_S_P95" "Studios P95" "true")"
        
        CUR_SR_P95=$(extract_value "$CURRENT_REPORT" "Search P95")
        PREV_SR_P95=$(extract_value "$PREVIOUS_REPORT" "Search P95")
        echo -e "  Search P95:       $(compare_values "$CUR_SR_P95" "$PREV_SR_P95" "Search P95" "true")"
        
        CUR_ERR=$(extract_value "$CURRENT_REPORT" "Concurrent Error Rate")
        PREV_ERR=$(extract_value "$PREVIOUS_REPORT" "Concurrent Error Rate")
        echo -e "  Error Rate:       $(compare_values "$CUR_ERR" "$PREV_ERR" "Error Rate" "true")"
    fi
    
    echo ""
    
    # Check for regressions
    echo -e "${BLUE}Regression Check:${NC}"
    echo ""
    
    HAS_REGRESSION=false
    
    if grep -q "Health Check P95" "$CURRENT_REPORT" && grep -q "Health Check P95" "$PREVIOUS_REPORT"; then
        CUR_H_P95=$(extract_value "$CURRENT_REPORT" "Health Check P95" | sed 's/[^0-9.]//g')
        PREV_H_P95=$(extract_value "$PREVIOUS_REPORT" "Health Check P95" | sed 's/[^0-9.]//g')
        
        if [ -n "$CUR_H_P95" ] && [ -n "$PREV_H_P95" ]; then
            # Check if response time increased by more than 20%
            THRESHOLD=$(echo "$PREV_H_P95 * 1.2" | bc)
            if (( $(echo "$CUR_H_P95 > $THRESHOLD" | bc -l) )); then
                echo -e "  ${RED}⚠️  Health Check P95 increased by more than 20%${NC}"
                HAS_REGRESSION=true
            fi
        fi
    fi
    
    if [ "$HAS_REGRESSION" = false ]; then
        echo -e "  ${GREEN}✅ No significant regressions detected${NC}"
    fi
fi

echo ""
echo "============================================"
echo "   Comparison Complete"
echo "============================================"
echo ""
