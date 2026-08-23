#!/bin/bash

# StudioBook API Stress Test
# Tests API under high concurrency

set -e

BASE_URL="${1:-http://localhost:8000/api/v1}"
CONCURRENT_USERS="${2:-50}"
REQUESTS_PER_USER="${3:-10}"
DURATION="${4:-60}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           StudioBook API Stress Test                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Base URL:         ${BASE_URL}"
echo -e "Concurrent Users: ${CONCURRENT_USERS}"
echo -e "Requests/User:    ${REQUESTS_PER_USER}"
echo -e "Duration:         ${DURATION}s"
echo ""

# Check dependencies
if ! command -v ab &> /dev/null && ! command -v wrk &> /dev/null && ! command -v siege &> /dev/null; then
    echo -e "${YELLOW}⚠ No stress testing tool found. Using curl-based test.${NC}"
    echo ""
    
    # Simple concurrent test with curl
    echo -e "${BLUE}Running concurrent requests...${NC}"
    
    for i in $(seq 1 $CONCURRENT_USERS); do
        (
            for j in $(seq 1 $REQUESTS_PER_USER); do
                curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health" &
            done
        ) &
    done
    
    wait
    
    echo -e "${GREEN}✓ Completed ${CONCURRENT_USERS} concurrent users${NC}"
    echo ""
    echo -e "${YELLOW}Install Apache Bench (ab) or wrk for detailed metrics:${NC}"
    echo -e "  Ubuntu/Debian: ${BLUE}sudo apt-get install apache2-utils${NC}"
    echo -e "  macOS: ${BLUE}brew install wrk${NC}"
    echo ""
    
    # Test with Apache Bench if available
    if command -v ab &> /dev/null; then
        echo -e "${BLUE}Running Apache Bench test...${NC}"
        echo ""
        
        echo -e "${YELLOW}--- Health Check ---${NC}"
        ab -n 1000 -c 50 -q "$BASE_URL/health" 2>/dev/null | grep -E "Requests per|Time per|Transfer rate"
        echo ""
        
        echo -e "${YELLOW}--- Studios List ---${NC}"
        ab -n 500 -c 25 -q "$BASE_URL/studios" 2>/dev/null | grep -E "Requests per|Time per|Transfer rate"
        echo ""
        
        echo -e "${YELLOW}--- Studio Search ---${NC}"
        ab -n 500 -c 25 -q "$BASE_URL/studios?search=music" 2>/dev/null | grep -E "Requests per|Time per|Transfer rate"
        echo ""
    fi
    
    # Test with wrk if available
    if command -v wrk &> /dev/null; then
        echo -e "${BLUE}Running wrk test...${NC}"
        echo ""
        
        echo -e "${YELLOW}--- Health Check ---${NC}"
        wrk -t4 -c${CONCURRENT_USERS} -d${DURATION}s "$BASE_URL/health" 2>/dev/null
        echo ""
        
        echo -e "${YELLOW}--- Studios List ---${NC}"
        wrk -t4 -c${CONCURRENT_USERS} -d${DURATION}s "$BASE_URL/studios" 2>/dev/null
        echo ""
        
        echo -e "${YELLOW}--- Studio Search ---${NC}"
        wrk -t4 -c${CONCURRENT_USERS} -d${DURATION}s "$BASE_URL/studios?search=music" 2>/dev/null
        echo ""
    fi
    
    # Test with siege if available
    if command -v siege &> /dev/null; then
        echo -e "${BLUE}Running siege test...${NC}"
        echo ""
        
        # Create siege config
        cat > /tmp/siege.conf << EOF
$BASE_URL/health
$BASE_URL/studios
$BASE_URL/studios?search=music
EOF
        
        siege -c${CONCURRENT_USERS} -d1 -r${REQUESTS_PER_USER} -f /tmp/siege.conf
        rm /tmp/siege.conf
        echo ""
    fi
    
    exit 0
fi

# Use Apache Bench
if command -v ab &> /dev/null; then
    echo -e "${BLUE}Running Apache Bench test...${NC}"
    echo ""
    
    echo -e "${YELLOW}--- Health Check ---${NC}"
    ab -n 1000 -c 50 -q "$BASE_URL/health"
    echo ""
    
    echo -e "${YELLOW}--- Studios List ---${NC}"
    ab -n 500 -c 25 -q "$BASE_URL/studios"
    echo ""
    
    echo -e "${YELLOW}--- Studio Search ---${NC}"
    ab -n 500 -c 25 -q "$BASE_URL/studios?search=music"
    echo ""
    
    echo -e "${GREEN}✓ Stress test completed${NC}"
    exit 0
fi

# Use wrk
if command -v wrk &> /dev/null; then
    echo -e "${BLUE}Running wrk test...${NC}"
    echo ""
    
    echo -e "${YELLOW}--- Health Check ---${NC}"
    wrk -t4 -c${CONCURRENT_USERS} -d${DURATION}s "$BASE_URL/health"
    echo ""
    
    echo -e "${YELLOW}--- Studios List ---${NC}"
    wrk -t4 -c${CONCURRENT_USERS} -d${DURATION}s "$BASE_URL/studios"
    echo ""
    
    echo -e "${YELLOW}--- Studio Search ---${NC}"
    wrk -t4 -c${CONCURRENT_USERS} -d${DURATION}s "$BASE_URL/studios?search=music"
    echo ""
    
    echo -e "${GREEN}✓ Stress test completed${NC}"
    exit 0
fi

# Use siege
if command -v siege &> /dev/null; then
    echo -e "${BLUE}Running siege test...${NC}"
    echo ""
    
    cat > /tmp/siege.conf << EOF
$BASE_URL/health
$BASE_URL/studios
$BASE_URL/studios?search=music
EOF
    
    siege -c${CONCURRENT_USERS} -d1 -r${REQUESTS_PER_USER} -f /tmp/siege.conf
    rm /tmp/siege.conf
    echo ""
    
    echo -e "${GREEN}✓ Stress test completed${NC}"
    exit 0
fi
