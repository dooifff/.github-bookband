#!/bin/bash

# StudioBook Quick API Test
# Usage: ./tests/quick_test.sh

BASE_URL="${1:-http://localhost:8000/api/v1}"

echo "🎵 StudioBook Quick API Test"
echo "============================"
echo ""

# Health Check
echo "1. Health Check"
curl -s "$BASE_URL/health" | jq .
echo ""

# Login
echo "2. Login as Customer"
TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@studiobook.com","password":"password"}' | jq -r '.data.token')
echo "Token: ${TOKEN:0:20}..."
echo ""

# Get Profile
echo "3. Get Profile"
curl -s "$BASE_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# List Studios
echo "4. List Studios"
curl -s "$BASE_URL/studios?per_page=3" | jq '.data.data[:2]'
echo ""

# List Bookings
echo "5. List Bookings"
curl -s "$BASE_URL/bookings" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

echo "✅ Quick test complete!"
