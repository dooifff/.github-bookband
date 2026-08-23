#!/bin/bash

# StudioBook API Test Automation Script
# Usage: ./tests/api_test.sh [environment]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${1:-http://localhost:8000/api/v1}"
PASSED=0
FAILED=0
TOTAL=0

# Test accounts
CUSTOMER_EMAIL="customer@studiobook.com"
CUSTOMER_PASSWORD="password"
ADMIN_EMAIL="admin@studiobook.com"
ADMIN_PASSWORD="password"
OWNER_EMAIL="owner@studiobook.com"
OWNER_PASSWORD="password"

# Tokens
CUSTOMER_TOKEN=""
ADMIN_TOKEN=""
OWNER_TOKEN=""

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  StudioBook API Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Base URL: ${BASE_URL}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${YELLOW}--- $1 ---${NC}"
}

print_test() {
    echo -n "  Testing: $1 ... "
}

print_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
    ((TOTAL++))
}

print_fail() {
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
    ((TOTAL++))
}

print_result() {
    local response="$1"
    local expected_status="$2"
    local actual_status=$(echo "$response" | grep -o '"success": true' | head -1)
    
    if [ -n "$actual_status" ] && [ "$expected_status" = "200" ]; then
        return 0
    elif [ -z "$actual_status" ] && [ "$expected_status" != "200" ]; then
        return 0
    fi
    return 1
}

# ============================================
# Health Check Tests
# ============================================
test_health_check() {
    print_section "Health Check"
    
    print_test "GET /health"
    local response=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
    local status_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)
    
    if [ "$status_code" = "200" ]; then
        print_pass
    else
        print_fail
        echo "    Expected: 200, Got: $status_code"
    fi
}

# ============================================
# Auth Tests
# ============================================
test_auth() {
    print_section "Authentication"
    
    # Login as Customer
    print_test "POST /auth/login (Customer)"
    local response=$(curl -s -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$CUSTOMER_EMAIL\",\"password\":\"$CUSTOMER_PASSWORD\"}")
    
    if echo "$response" | grep -q '"success": true'; then
        CUSTOMER_TOKEN=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Login as Admin
    print_test "POST /auth/login (Admin)"
    local response=$(curl -s -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")
    
    if echo "$response" | grep -q '"success": true'; then
        ADMIN_TOKEN=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Login as Owner
    print_test "POST /auth/login (Owner)"
    local response=$(curl -s -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$OWNER_EMAIL\",\"password\":\"$OWNER_PASSWORD\"}")
    
    if echo "$response" | grep -q '"success": true'; then
        OWNER_TOKEN=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Profile
    print_test "GET /auth/me"
    local response=$(curl -s "$BASE_URL/auth/me" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Update Profile
    print_test "PUT /auth/profile"
    local response=$(curl -s -X PUT "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test Customer Updated"}')
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Studio Tests
# ============================================
test_studios() {
    print_section "Studios"
    
    # List Studios
    print_test "GET /studios"
    local response=$(curl -s "$BASE_URL/studios?per_page=5")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Search Studios
    print_test "GET /studios?search=music"
    local response=$(curl -s "$BASE_URL/studios?search=music")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Studio by Slug
    print_test "GET /studios/{slug}"
    local response=$(curl -s "$BASE_URL/studios/studio-melody-1")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Studio Rooms
    print_test "GET /studios/{slug}/rooms"
    local response=$(curl -s "$BASE_URL/studios/studio-melody-1/rooms")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Check Availability
    print_test "GET /studios/{slug}/availability"
    local response=$(curl -s "$BASE_URL/studios/studio-melody-1/availability?date=2025-03-15&start_time=10:00&end_time=12:00")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Booking Tests
# ============================================
test_bookings() {
    print_section "Bookings"
    
    # List Bookings
    print_test "GET /bookings"
    local response=$(curl -s "$BASE_URL/bookings" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Create Booking
    print_test "POST /bookings"
    local response=$(curl -s -X POST "$BASE_URL/bookings" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "studio_id": 1,
            "room_id": 1,
            "date": "2025-03-20",
            "start_time": "10:00",
            "end_time": "12:00",
            "notes": "Test booking"
        }')
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Booking Detail
    print_test "GET /bookings/{id}"
    local response=$(curl -s "$BASE_URL/bookings/1" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Payment Tests
# ============================================
test_payments() {
    print_section "Payments"
    
    # Get Payment History
    print_test "GET /payment-history"
    local response=$(curl -s "$BASE_URL/payment-history" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Create Payment
    print_test "POST /payments"
    local response=$(curl -s -X POST "$BASE_URL/payments" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "booking_id": 1,
            "payment_method": "bank_transfer",
            "provider": "midtrans"
        }')
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Favorite Tests
# ============================================
test_favorites() {
    print_section "Favorites"
    
    # List Favorites
    print_test "GET /favorites"
    local response=$(curl -s "$BASE_URL/favorites" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Toggle Favorite
    print_test "POST /favorites/toggle"
    local response=$(curl -s -X POST "$BASE_URL/favorites/toggle" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"studio_id": 1}')
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Check Favorite Status
    print_test "GET /favorites/check/{studioId}"
    local response=$(curl -s "$BASE_URL/favorites/check/1" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Review Tests
# ============================================
test_reviews() {
    print_section "Reviews"
    
    # Get My Reviews
    print_test "GET /reviews/my-reviews"
    local response=$(curl -s "$BASE_URL/reviews/my-reviews" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Studio Reviews (Public)
    print_test "GET /studios/{slug}/reviews"
    local response=$(curl -s "$BASE_URL/studios/studio-melody-1/reviews")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Band Tests
# ============================================
test_bands() {
    print_section "Bands"
    
    # List My Bands
    print_test "GET /bands"
    local response=$(curl -s "$BASE_URL/bands" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Create Band
    print_test "POST /bands"
    local response=$(curl -s -X POST "$BASE_URL/bands" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Test Band",
            "description": "A test band",
            "genre": "Rock"
        }')
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Notification Tests
# ============================================
test_notifications() {
    print_section "Notifications"
    
    # List Notifications
    print_test "GET /notifications"
    local response=$(curl -s "$BASE_URL/notifications" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Unread Count
    print_test "GET /notifications/unread-count"
    local response=$(curl -s "$BASE_URL/notifications/unread-count" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Mark All as Read
    print_test "POST /notifications/read-all"
    local response=$(curl -s -X POST "$BASE_URL/notifications/read-all" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Membership Tests
# ============================================
test_membership() {
    print_section "Membership"
    
    # List Plans
    print_test "GET /membership/plans"
    local response=$(curl -s "$BASE_URL/membership/plans" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Current Membership
    print_test "GET /membership/current"
    local response=$(curl -s "$BASE_URL/membership/current" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Check Discount
    print_test "GET /membership/discount"
    local response=$(curl -s "$BASE_URL/membership/discount" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Promo Tests
# ============================================
test_promos() {
    print_section "Promos"
    
    # List Promos
    print_test "GET /promos"
    local response=$(curl -s "$BASE_URL/promos" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Validate Promo Code
    print_test "POST /promos/validate"
    local response=$(curl -s -X POST "$BASE_URL/promos/validate" \
        -H "Authorization: Bearer $CUSTOMER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"code":"WEEKEND10","booking_amount":200000}')
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Owner Tests
# ============================================
test_owner() {
    print_section "Owner Endpoints"
    
    # Get Dashboard
    print_test "GET /owner/dashboard"
    local response=$(curl -s "$BASE_URL/owner/dashboard" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # List My Studios
    print_test "GET /owner/studios"
    local response=$(curl -s "$BASE_URL/owner/studios" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # List Owner Bookings
    print_test "GET /owner/bookings"
    local response=$(curl -s "$BASE_URL/owner/bookings" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Revenue
    print_test "GET /owner/revenue"
    local response=$(curl -s "$BASE_URL/owner/revenue" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Admin Tests
# ============================================
test_admin() {
    print_section "Admin Endpoints"
    
    # Get Dashboard
    print_test "GET /admin/dashboard"
    local response=$(curl -s "$BASE_URL/admin/dashboard" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # List Users
    print_test "GET /admin/users"
    local response=$(curl -s "$BASE_URL/admin/users" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get User Stats
    print_test "GET /admin/users/stats"
    local response=$(curl -s "$BASE_URL/admin/users/stats" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # List Studios
    print_test "GET /admin/studios"
    local response=$(curl -s "$BASE_URL/admin/studios" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
    
    # Get Studio Stats
    print_test "GET /admin/studios/stats"
    local response=$(curl -s "$BASE_URL/admin/studios/stats" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    
    if echo "$response" | grep -q '"success": true'; then
        print_pass
    else
        print_fail
        echo "    Response: $response"
    fi
}

# ============================================
# Print Summary
# ============================================
print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "Total Tests:  ${TOTAL}"
    echo -e "${GREEN}Passed:       ${PASSED}${NC}"
    echo -e "${RED}Failed:       ${FAILED}${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# ============================================
# Main
# ============================================
main() {
    print_header
    
    # Check if server is running
    print_test "Server connectivity"
    if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health" | grep -q "200"; then
        print_pass
    else
        echo -e "${RED}Server is not running at $BASE_URL${NC}"
        echo "Please start the server first: php artisan serve"
        exit 1
    fi
    
    # Run tests
    test_health_check
    test_auth
    test_studios
    test_bookings
    test_payments
    test_favorites
    test_reviews
    test_bands
    test_notifications
    test_membership
    test_promos
    test_owner
    test_admin
    
    # Print summary
    print_summary
}

# Run main function
main
