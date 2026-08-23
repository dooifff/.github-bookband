#!/bin/bash

# StudioBook Database Performance Test
# Tests database query performance

set -e

BASE_URL="${1:-http://localhost:8000/api/v1}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudioBook Database Performance Test             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test database-intensive endpoints
echo -e "${YELLOW}Testing database-intensive queries...${NC}"
echo ""

# Test 1: Studios with rooms and reviews (JOIN query)
echo -e "${BLUE}1. Studios with related data (JOINs)...${NC}"
start_time=$(date +%s%N)
for i in {1..100}; do
    curl -s -o /dev/null "$BASE_URL/studios?per_page=20" &
done
wait
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo -e "   ${GREEN}✓ 100 requests completed in ${duration}ms${NC}"
echo ""

# Test 2: Studio search (Full-text search)
echo -e "${BLUE}2. Studio search (Full-text search)...${NC}"
start_time=$(date +%s%N)
for i in {1..100}; do
    curl -s -o /dev/null "$BASE_URL/studios?search=music+studio" &
done
wait
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo -e "   ${GREEN}✓ 100 search requests completed in ${duration}ms${NC}"
echo ""

# Test 3: Studio detail with rooms, equipment, reviews
echo -e "${BLUE}3. Studio detail with nested data...${NC}"
start_time=$(date +%s%N)
for i in {1..100}; do
    curl -s -o /dev/null "$BASE_URL/studios/1" &
done
wait
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo -e "   ${GREEN}✓ 100 detail requests completed in ${duration}ms${NC}"
echo ""

# Test 4: Favorites list with studios
echo -e "${BLUE}4. Favorites list with studio data...${NC}"
TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"customer@studiobook.com","password":"password"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    start_time=$(date +%s%N)
    for i in {1..100}; do
        curl -s -o /dev/null -H "Authorization: Bearer $TOKEN" "$BASE_URL/favorites" &
    done
    wait
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    echo -e "   ${GREEN}✓ 100 favorites requests completed in ${duration}ms${NC}"
else
    echo -e "   ${YELLOW}⚠ Skipped (no auth token)${NC}"
fi
echo ""

# Test 5: Bookings list with studios
echo -e "${BLUE}5. Bookings list with studio data...${NC}"
if [ -n "$TOKEN" ]; then
    start_time=$(date +%s%N)
    for i in {1..100}; do
        curl -s -o /dev/null -H "Authorization: Bearer $TOKEN" "$BASE_URL/bookings" &
    done
    wait
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    echo -e "   ${GREEN}✓ 100 bookings requests completed in ${duration}ms${NC}"
else
    echo -e "   ${YELLOW}⚠ Skipped (no auth token)${NC}"
fi
echo ""

# Test 6: Reviews list with users
echo -e "${BLUE}6. Reviews list with user data...${NC}"
start_time=$(date +%s%N)
for i in {1..100}; do
    curl -s -o /dev/null "$BASE_URL/studios/1/reviews" &
done
wait
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo -e "   ${GREEN}✓ 100 reviews requests completed in ${duration}ms${NC}"
echo ""

# Test 7: Notifications list
echo -e "${BLUE}7. Notifications list...${NC}"
if [ -n "$TOKEN" ]; then
    start_time=$(date +%s%N)
    for i in {1..100}; do
        curl -s -o /dev/null -H "Authorization: Bearer $TOKEN" "$BASE_URL/notifications" &
    done
    wait
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    echo -e "   ${GREEN}✓ 100 notifications requests completed in ${duration}ms${NC}"
else
    echo -e "   ${YELLOW}⚠ Skipped (no auth token)${NC}"
fi
echo ""

# Test 8: Mixed workload
echo -e "${BLUE}8. Mixed workload (50% reads, 25% writes, 25% auth)...${NC}"
start_time=$(date +%s%N)

# 50 reads
for i in {1..25}; do
    curl -s -o /dev/null "$BASE_URL/studios" &
done
for i in {1..25}; do
    curl -s -o /dev/null "$BASE_URL/studios/1" &
done

# 25 writes (favorites toggle)
if [ -n "$TOKEN" ]; then
    for i in {1..25}; do
        curl -s -o /dev/null -X POST -H "Authorization: Bearer $TOKEN" "$BASE_URL/favorites/1/toggle" &
    done
fi

# 25 auth requests
for i in {1..25}; do
    curl -s -o /dev/null -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"customer@studiobook.com","password":"password"}' &
done

wait
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo -e "   ${GREEN}✓ 100 mixed requests completed in ${duration}ms${NC}"
echo ""

echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Database performance test completed!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
