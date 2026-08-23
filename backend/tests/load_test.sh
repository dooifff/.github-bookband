#!/bin/bash

# StudioBook Simple Load Test (using curl)
# Usage: ./tests/load_test.sh [base_url] [requests]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BASE_URL="${1:-http://localhost:8000/api/v1}"
REQUESTS="${2:-50}"
RESULTS_DIR="performance_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  StudioBook Load Test (curl-based)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Base URL: ${CYAN}$BASE_URL${NC}"
echo -e "Requests: ${CYAN}$REQUESTS${NC}"
echo ""

# Get auth token
echo -e "${CYAN}Getting authentication token...${NC}"
TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"customer@studiobook.com","password":"password"}' | \
    grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Failed to get auth token.${NC}"
    exit 1
fi
echo -e "${GREEN}Token obtained!${NC}"
echo ""

# Function to run load test
run_load_test() {
    local name=$1
    local url=$2
    local auth_header=$3
    
    echo -e "${YELLOW}Testing: $name${NC}"
    
    local total_time=0
    local success_count=0
    local fail_count=0
    local start_time=$(date +%s%N)
    
    for i in $(seq 1 $REQUESTS); do
        local request_start=$(date +%s%N)
        
        if [ -n "$auth_header" ]; then
            response=$(curl -s -o /dev/null -w "%{http_code}" \
                -H "Authorization: Bearer $TOKEN" \
                "$url")
        else
            response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
        fi
        
        local request_end=$(date +%s%N)
        local request_time=$(( (request_end - request_start) / 1000000 ))
        total_time=$((total_time + request_time))
        
        if [ "$response" = "200" ]; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        
        # Progress indicator
        if (( i % 10 == 0 )); then
            echo -n "."
        fi
    done
    
    local end_time=$(date +%s%N)
    local total_duration=$(( (end_time - start_time) / 1000000 ))
    local avg_time=$((total_time / REQUESTS))
    local rps=$(echo "scale=2; $REQUESTS / ($total_duration / 1000)" | bc)
    local success_rate=$(echo "scale=2; $success_count / $REQUESTS * 100" | bc)
    
    echo ""
    echo -e "  ${GREEN}Results:${NC}"
    echo -e "    Total Time:    ${total_duration}ms"
    echo -e "    Avg Response:  ${avg_time}ms"
    echo -e "    Requests/sec:  ${rps}"
    echo -e "    Success Rate:  ${success_rate}%"
    echo -e "    Successful:    ${success_count}/${REQUESTS}"
    echo ""
    
    # Save to file
    echo "Test: $name" >> "$RESULTS_DIR/load_test_$TIMESTAMP.txt"
    echo "URL: $url" >> "$RESULTS_DIR/load_test_$TIMESTAMP.txt"
    echo "Requests: $REQUESTS" >> "$RESULTS_DIR/load_test_$TIMESTAMP.txt"
    echo "Total Time: ${total_duration}ms" >> "$RESULTS_DIR/load_test_$TIMESTAMP.txt"
    echo "Avg Response: ${avg_time}ms" >> "$RESULTS_DIR/load_test_$TIMESTAMP.txt"
    echo "Requests/sec: ${rps}" >> "$RESULTS_DIR/load_test_$TIMESTAMP.txt"
    echo "Success Rate: ${success_rate}%" >> "$RESULTS_DIR/load_test_$TIMESTAMP.txt"
    echo "---" >> "$RESULTS_DIR/load_test_$TIMESTAMP.txt"
}

# ============================================
# Run Load Tests
# ============================================

run_load_test "Health Check" "$BASE_URL/health"

run_load_test "List Studios" "$BASE_URL/studios?per_page=20"

run_load_test "Search Studios" "$BASE_URL/studios?search=music"

run_load_test "Get Studio Detail" "$BASE_URL/studios/studio-melody-1"

run_load_test "List Bookings (Auth)" "$BASE_URL/bookings" "auth"

run_load_test "List Favorites (Auth)" "$BASE_URL/favorites" "auth"

run_load_test "Get Profile (Auth)" "$BASE_URL/auth/me" "auth"

# ============================================
# Summary
# ============================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Load Test Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Results saved to: $RESULTS_DIR/load_test_$TIMESTAMP.txt${NC}"
echo ""

# Display summary
echo -e "${CYAN}Summary:${NC}"
grep -E "^(Test|Avg Response|Requests/sec|Success Rate):" "$RESULTS_DIR/load_test_$TIMESTAMP.txt" | while read -r line; do
    echo -e "  $line"
done

echo ""
