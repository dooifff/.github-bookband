#!/bin/bash

# StudioBook Performance Test Script
# Usage: ./tests/performance_test.sh [base_url] [concurrent] [requests]

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
CONCURRENT="${2:-10}"
REQUESTS="${3:-100}"
RESULTS_DIR="performance_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create results directory
mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  StudioBook Performance Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Base URL:     ${CYAN}$BASE_URL${NC}"
echo -e "Concurrent:   ${CYAN}$CONCURRENT${NC}"
echo -e "Requests:     ${CYAN}$REQUESTS${NC}"
echo ""

# Check if hey is installed
if ! command -v hey &> /dev/null; then
    echo -e "${YELLOW}Installing 'hey' load testing tool...${NC}"
    
    # Try to install hey
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hey 2>/dev/null || {
            echo -e "${RED}Failed to install hey. Please install manually:${NC}"
            echo "  brew install hey"
            echo "  OR"
            echo "  go install github.com/rakyll/hey@latest"
            exit 1
        }
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v go &> /dev/null; then
            go install github.com/rakyll/hey@latest
        else
            echo -e "${RED}Please install 'hey' manually:${NC}"
            echo "  go install github.com/rakyll/hey@latest"
            echo "  OR"
            echo "  Download from: https://github.com/rakyll/hey/releases"
            exit 1
        fi
    fi
fi

# Function to run performance test
run_test() {
    local name=$1
    local url=$2
    local method=$3
    local data=$4
    local headers=$5
    
    echo -e "${YELLOW}Testing: $name${NC}"
    echo -e "URL: $url"
    echo ""
    
    local output_file="$RESULTS_DIR/${name// /_}_$TIMESTAMP.txt"
    
    if [ -n "$data" ]; then
        hey -n "$REQUESTS" -c "$CONCURRENT" -m "$method" \
            -H "$headers" \
            -d "$data" \
            "$url" | tee "$output_file"
    elif [ -n "$method" ] && [ "$method" != "GET" ]; then
        hey -n "$REQUESTS" -c "$CONCURRENT" -m "$method" \
            -H "$headers" \
            "$url" | tee "$output_file"
    else
        hey -n "$REQUESTS" -c "$CONCURRENT" \
            "$url" | tee "$output_file"
    fi
    
    echo ""
    echo -e "${GREEN}Results saved to: $output_file${NC}"
    echo ""
    echo "-------------------------------------------"
    echo ""
}

# ============================================
# Get auth token
# ============================================
echo -e "${CYAN}Getting authentication token...${NC}"
TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"customer@studiobook.com","password":"password"}' | \
    grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Failed to get auth token. Make sure server is running and seeded.${NC}"
    exit 1
fi

echo -e "${GREEN}Token obtained!${NC}"
echo ""

# ============================================
# Performance Tests
# ============================================

# 1. Health Check (No Auth)
run_test "01_Health_Check" "$BASE_URL/health" "GET"

# 2. Login (POST with body)
run_test "02_Login" "$BASE_URL/auth/login" "POST" \
    '{"email":"customer@studiobook.com","password":"password"}' \
    "Content-Type: application/json"

# 3. Get Profile (Auth Required)
run_test "03_Get_Profile" "$BASE_URL/auth/me" "GET" "" \
    "Authorization: Bearer $TOKEN"

# 4. List Studios (Public)
run_test "04_List_Studios" "$BASE_URL/studios?per_page=20" "GET"

# 5. Search Studios
run_test "05_Search_Studios" "$BASE_URL/studios?search=music&city=Jakarta" "GET"

# 6. Get Studio Detail
run_test "06_Studio_Detail" "$BASE_URL/studios/studio-melody-1" "GET"

# 7. List Bookings (Auth Required)
run_test "07_List_Bookings" "$BASE_URL/bookings" "GET" "" \
    "Authorization: Bearer $TOKEN"

# 8. List Favorites (Auth Required)
run_test "08_List_Favorites" "$BASE_URL/favorites" "GET" "" \
    "Authorization: Bearer $TOKEN"

# 9. Get Notifications (Auth Required)
run_test "09_List_Notifications" "$BASE_URL/notifications" "GET" "" \
    "Authorization: Bearer $TOKEN"

# 10. Get Membership Plans (Auth Required)
run_test "10_Membership_Plans" "$BASE_URL/membership/plans" "GET" "" \
    "Authorization: Bearer $TOKEN"

# 11. List Promos (Auth Required)
run_test "11_List_Promos" "$BASE_URL/promos" "GET" "" \
    "Authorization: Bearer $TOKEN"

# 12. Owner Dashboard (Owner Auth Required)
OWNER_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"owner@studiobook.com","password":"password"}' | \
    grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$OWNER_TOKEN" ]; then
    run_test "12_Owner_Dashboard" "$BASE_URL/owner/dashboard" "GET" "" \
        "Authorization: Bearer $OWNER_TOKEN"
fi

# ============================================
# Generate Summary Report
# ============================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Performance Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

REPORT_FILE="$RESULTS_DIR/summary_$TIMESTAMP.md"

cat > "$REPORT_FILE" << EOF
# StudioBook Performance Test Report

**Date:** $(date)
**Base URL:** $BASE_URL
**Concurrent Users:** $CONCURRENT
**Total Requests per Test:** $REQUESTS

---

## Test Results

| Test | Avg Response Time | Requests/sec | Success Rate |
|------|-------------------|--------------|--------------|
EOF

# Parse results and add to report
for file in "$RESULTS_DIR"/*_$TIMESTAMP.txt; do
    if [ -f "$file" ]; then
        test_name=$(basename "$file" | sed "s/_$TIMESTAMP.txt//")
        avg_time=$(grep "Average:" "$file" | awk '{print $2}')
        rps=$(grep "Requests/sec:" "$file" | awk '{print $2}')
        success_rate=$(grep "Status code distribution" -A 20 "$file" | grep "200" | awk '{print $2}')
        
        if [ -n "$avg_time" ]; then
            echo "| $test_name | ${avg_time}s | ${rps:-N/A} | ${success_rate:-N/A} |" >> "$REPORT_FILE"
        fi
    fi
done

cat >> "$REPORT_FILE" << EOF

---

## Recommendations

1. **Response Time:** Aim for < 200ms for API endpoints
2. **Throughput:** Target > 50 requests/second
3. **Error Rate:** Should be < 1%

---

## Files Generated

- Individual results: \`$RESULTS_DIR/*_$TIMESTAMP.txt\`
- Summary report: \`$REPORT_FILE\`
EOF

echo -e "${GREEN}Summary report generated: $REPORT_FILE${NC}"
echo ""

# Display summary
echo -e "${CYAN}Quick Summary:${NC}"
for file in "$RESULTS_DIR"/*_$TIMESTAMP.txt; do
    if [ -f "$file" ]; then
        test_name=$(basename "$file" | sed "s/_$TIMESTAMP.txt//" | tr '_' ' ')
        avg_time=$(grep "Average:" "$file" | awk '{print $2}')
        rps=$(grep "Requests/sec:" "$file" | awk '{print $2}')
        echo -e "  ${test_name}: ${avg_time:-N/A}s avg, ${rps:-N/A} req/s"
    fi
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Performance tests complete!${NC}"
echo -e "${BLUE}========================================${NC}"
