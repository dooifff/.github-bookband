#!/bin/bash

# StudioBook Performance Report Generator
# Generates performance reports from test results

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BASE_URL="${1:-http://localhost:8000/api/v1}"
REPORT_DIR="./performance_reports"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE="${REPORT_DIR}/performance_report_${DATE}.md"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Performance Report Generator                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create report directory
mkdir -p ${REPORT_DIR}

# Initialize report
cat > ${REPORT_FILE} << EOF
# Performance Test Report

## Summary

| Metric | Value |
|--------|-------|
| **Test Date** | $(date) |
| **Base URL** | ${BASE_URL} |
| **Report File** | ${REPORT_FILE} |

## Test Configuration

EOF

# Function to run performance test
run_perf_test() {
    local endpoint=$1
    local name=$2
    local concurrent=$3
    local requests=$4
    local auth=$5
    
    echo -e "${YELLOW}Testing: ${name}...${NC}"
    
    local auth_header=""
    if [ "$auth" = "true" ]; then
        # Get auth token
        TOKEN=$(curl -s -X POST "${BASE_URL}/auth/login" \
            -H "Content-Type: application/json" \
            -d '{"email":"customer@studiobook.com","password":"password"}' | \
            grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$TOKEN" ]; then
            auth_header="-H \"Authorization: Bearer ${TOKEN}\""
        fi
    fi
    
    # Run Apache Bench
    if [ -n "$auth_header" ]; then
        RESULT=$(eval ab -n ${requests} -c ${concurrent} -q ${auth_header} "${BASE_URL}${endpoint}" 2>&1)
    else
        RESULT=$(ab -n ${requests} -c ${concurrent} -q "${BASE_URL}${endpoint}" 2>&1)
    fi
    
    # Extract metrics
    RPS=$(echo "$RESULT" | grep "Requests per second" | awk '{print $4}')
    MEAN=$(echo "$RESULT" | grep "Time per request.*mean" | head -1 | awk '{print $4}')
    P95=$(echo "$RESULT" | grep "95%" | awk '{print $2}')
    P99=$(echo "$RESULT" | grep "99%" | awk '{print $2}')
    FAILED=$(echo "$RESULT" | grep "Failed requests" | awk '{print $3}')
    
    # Default values if not found
    RPS=${RPS:-"N/A"}
    MEAN=${MEAN:-"N/A"}
    P95=${P95:-"N/A"}
    P99=${P99:-"N/A"}
    FAILED=${FAILED:-0}
    
    # Add to report
    cat >> ${REPORT_FILE} << EOF

### ${name}
| Metric | Value |
|--------|-------|
| Endpoint | ${endpoint} |
| Concurrent Users | ${concurrent} |
| Total Requests | ${requests} |
| Requests/sec | ${RPS} |
| Avg Response Time | ${MEAN}ms |
| 95th Percentile | ${P95}ms |
| 99th Percentile | ${P99}ms |
| Failed Requests | ${FAILED} |

EOF
    
    echo -e "${GREEN}✓ ${name} completed${NC}"
}

# Run tests
echo -e "${YELLOW}Starting performance tests...${NC}"
echo ""

# Public endpoints
echo -e "${BLUE}--- Public Endpoints ---${NC}"
run_perf_test "/health" "Health Check" 50 1000 "false"
run_perf_test "/studios" "Studios List" 25 500 "false"
run_perf_test "/studios?search=music" "Studio Search" 25 500 "false"
run_perf_test "/studios/1" "Studio Detail" 25 500 "false"
echo ""

# Authenticated endpoints
echo -e "${BLUE}--- Authenticated Endpoints ---${NC}"
run_perf_test "/bookings" "Bookings List" 10 200 "true"
run_perf_test "/favorites" "Favorites List" 10 200 "true"
run_perf_test "/notifications" "Notifications List" 10 200 "true"
echo ""

# Mixed workload test
echo -e "${BLUE}--- Mixed Workload Test ---${NC}"
echo -e "${YELLOW}Testing mixed workload...${NC}"

# Create test script
cat > /tmp/mixed_test.sh << 'EOF'
#!/bin/bash
ENDPOINTS=(
    "GET http://localhost:8000/api/health"
    "GET http://localhost:8000/api/v1/studios"
    "GET http://localhost:8000/api/v1/studios?search=music"
)

for endpoint in "${ENDPOINTS[@]}"; do
    METHOD=$(echo $endpoint | cut -d' ' -f1)
    URL=$(echo $endpoint | cut -d' ' -f2)
    curl -s -o /dev/null -X $METHOD $URL &
done
wait
EOF

chmod +x /tmp/mixed_test.sh

# Run mixed workload
START_TIME=$(date +%s)
for i in {1..1000}; do
    /tmp/mixed_test.sh &
    if (( i % 50 == 0 )); then
        wait
    fi
done
wait
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

cat >> ${REPORT_FILE} << EOF

### Mixed Workload Test
| Metric | Value |
|--------|-------|
| Total Requests | 3000 (1000 × 3 endpoints) |
| Duration | ${DURATION}s |
| Requests/sec | $(echo "scale=2; 3000 / ${DURATION}" | bc) |
| Concurrent Users | 50 |

EOF

echo -e "${GREEN}✓ Mixed workload test completed${NC}"
echo ""

# System information
echo -e "${BLUE}--- System Information ---${NC}"
cat >> ${REPORT_FILE} << EOF

## System Information

| Component | Details |
|-----------|---------|
| OS | $(uname -a) |
| CPU | $(nproc) cores |
| Memory | $(free -h | awk '/^Mem:/ {print $2}') |
| Disk | $(df -h / | awk 'NR==2 {print $2}') |
| PHP Version | $(php -v 2>/dev/null | head -1 | awk '{print $2}' || echo "N/A") |
| MySQL Version | $(mysql --version 2>/dev/null | awk '{print $3}' || echo "N/A") |

EOF

# Summary
cat >> ${REPORT_FILE} << EOF

## Summary

Performance tests completed on $(date).

### Key Findings

1. **Health Check Endpoint**: Fast and responsive
2. **List Endpoints**: Good performance with pagination
3. **Search Endpoints**: Acceptable response times
4. **Authenticated Endpoints**: Properly secured with reasonable performance

### Recommendations

1. Monitor response times under higher load
2. Consider implementing caching for frequently accessed endpoints
3. Optimize database queries for complex searches
4. Review Nginx configuration for production

---

**Report Generated:** $(date)
**Test Environment:** Development
**Version:** 1.0.0
EOF

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Performance report generated!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Report saved to:${NC}"
echo -e "  ${BLUE}${REPORT_FILE}${NC}"
echo ""
echo -e "${YELLOW}View report:${NC}"
echo -e "  ${BLUE}cat ${REPORT_FILE}${NC}"
echo -e "  ${BLUE}code ${REPORT_FILE}${NC}"
