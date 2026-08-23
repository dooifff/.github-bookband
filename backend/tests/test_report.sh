#!/bin/bash

# StudioBook API Test Report Generator
# Usage: ./tests/test_report.sh

BASE_URL="${1:-http://localhost:8000/api/v1}"
REPORT_FILE="test_report_$(date +%Y%m%d_%H%M%S).md"

echo "📊 Generating API Test Report..."
echo ""

# Initialize report
cat > "$REPORT_FILE" << EOF
# StudioBook API Test Report

**Date:** $(date)
**Base URL:** $BASE_URL

---

## Test Results

| Endpoint | Method | Status | Response Time |
|----------|--------|--------|---------------|
EOF

# Test function
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    local start_time=$(date +%s%N)
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint")
    fi
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    local status_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)
    
    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
        local status="✅ PASS"
    elif [ "$status_code" -ge 400 ] && [ "$status_code" -lt 500 ]; then
        local status="⚠️ Client Error"
    else
        local status="❌ FAIL"
    fi
    
    echo "| $endpoint | $method | $status ($status_code) | ${duration}ms |" >> "$REPORT_FILE"
}

# Run tests
test_endpoint "GET" "/health" "Health Check"
test_endpoint "POST" "/auth/login" "Login" '{"email":"customer@studiobook.com","password":"password"}'
test_endpoint "GET" "/studios" "List Studios"
test_endpoint "GET" "/studios?search=music" "Search Studios"
test_endpoint "GET" "/promos" "List Promos"

# Add summary
cat >> "$REPORT_FILE" << EOF

---

## Summary

- **Total Tests:** 5
- **Report Generated:** $(date)

---

## Notes

- All responses should return \`"success": true\`
- Authentication endpoints return tokens
- List endpoints support pagination
EOF

echo ""
echo "✅ Report generated: $REPORT_FILE"
echo ""
cat "$REPORT_FILE"
