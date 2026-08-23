# StudioBook API Test Commands

## Prerequisites

```bash
# Start the development server
cd backend
php artisan serve

# In another terminal, seed the database
php artisan migrate:fresh --seed
```

---

## 🔓 Public Endpoints

### Health Check
```bash
curl http://localhost:8000/api/health
```

### Register
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New User",
    "email": "newuser@example.com",
    "phone": "08123456789",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

### Login as Customer
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "customer@studiobook.com",
    "password": "password"
  }'
```

### Login as Owner
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "owner@studiobook.com",
    "password": "password"
  }'
```

### Login as Admin
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@studiobook.com",
    "password": "password"
  }'
```

---

## 🔒 Protected Endpoints (Customer)

> **Note:** Replace `YOUR_TOKEN` with the token from login response

### Get Profile
```bash
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Update Profile
```bash
curl -X PUT http://localhost:8000/api/v1/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "phone": "08987654321"
  }'
```

### Change Password
```bash
curl -X PUT http://localhost:8000/api/v1/auth/password \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "password",
    "password": "newpassword",
    "password_confirmation": "newpassword"
  }'
```

---

## 🏠 Studios (Public)

### List Studios
```bash
curl "http://localhost:8000/api/v1/studios?per_page=5"
```

### Search Studios
```bash
curl "http://localhost:8000/api/v1/studios?search=music&city=Jakarta"
```

### Get Studio by Slug
```bash
curl "http://localhost:8000/api/v1/studios/studio-melody-1"
```

### Get Studio Rooms
```bash
curl "http://localhost:8000/api/v1/studios/studio-melody-1/rooms"
```

### Check Availability
```bash
curl "http://localhost:8000/api/v1/studios/studio-melody-1/availability?date=2025-03-15&start_time=10:00&end_time=12:00"
```

---

## 📅 Bookings (Customer)

### List My Bookings
```bash
curl http://localhost:8000/api/v1/bookings \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Create Booking
```bash
curl -X POST http://localhost:8000/api/v1/bookings \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "studio_id": 1,
    "room_id": 1,
    "date": "2025-03-20",
    "start_time": "10:00",
    "end_time": "12:00",
    "notes": "Need extra microphones"
  }'
```

### Get Booking Detail
```bash
curl http://localhost:8000/api/v1/bookings/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Cancel Booking
```bash
curl -X POST http://localhost:8000/api/v1/bookings/1/cancel \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 💳 Payments (Customer)

### Create Payment
```bash
curl -X POST http://localhost:8000/api/v1/payments \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": 1,
    "payment_method": "bank_transfer",
    "provider": "midtrans"
  }'
```

### Get Payment Status
```bash
curl http://localhost:8000/api/v1/payments/PAY12345678/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get Payment History
```bash
curl http://localhost:8000/api/v1/payment-history \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## ❤️ Favorites (Customer)

### List Favorites
```bash
curl http://localhost:8000/api/v1/favorites \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Toggle Favorite
```bash
curl -X POST http://localhost:8000/api/v1/favorites/toggle \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "studio_id": 1
  }'
```

### Check Favorite Status
```bash
curl http://localhost:8000/api/v1/favorites/check/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## ⭐ Reviews (Customer)

### Create Review
```bash
curl -X POST http://localhost:8000/api/v1/reviews \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "studio_id": 1,
    "booking_id": 1,
    "rating": 5,
    "comment": "Great studio!",
    "is_anonymous": false
  }'
```

### Get My Reviews
```bash
curl http://localhost:8000/api/v1/reviews/my-reviews \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🔔 Notifications (Customer)

### List Notifications
```bash
curl http://localhost:8000/api/v1/notifications \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get Unread Count
```bash
curl http://localhost:8000/api/v1/notifications/unread-count \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Mark All as Read
```bash
curl -X POST http://localhost:8000/api/v1/notifications/read-all \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 👥 Bands (Customer)

### List My Bands
```bash
curl http://localhost:8000/api/v1/bands \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Create Band
```bash
curl -X POST http://localhost:8000/api/v1/bands \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Rock Band",
    "description": "A rock band from Jakarta",
    "genre": "Rock"
  }'
```

### Invite Member
```bash
curl -X POST http://localhost:8000/api/v1/bands/1/invite \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "member@example.com"
  }'
```

---

## 🎫 Membership (Customer)

### List Membership Plans
```bash
curl http://localhost:8000/api/v1/membership/plans \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get Current Membership
```bash
curl http://localhost:8000/api/v1/membership/current \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Subscribe to Plan
```bash
curl -X POST http://localhost:8000/api/v1/membership/subscribe \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "plan_id": 1
  }'
```

### Check Discount
```bash
curl http://localhost:8000/api/v1/membership/discount \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🎁 Referral (Customer)

### Get Referral Info
```bash
curl http://localhost:8000/api/v1/referral \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Validate Referral Code
```bash
curl -X POST http://localhost:8000/api/v1/referral/validate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "ABC12345"
  }'
```

---

## 🏪 Owner Endpoints

> **Note:** Use owner_token from login as owner@studiobook.com

### Get Dashboard
```bash
curl http://localhost:8000/api/v1/owner/dashboard \
  -H "Authorization: Bearer OWNER_TOKEN"
```

### List My Studios
```bash
curl http://localhost:8000/api/v1/owner/studios \
  -H "Authorization: Bearer OWNER_TOKEN"
```

### Create Studio
```bash
curl -X POST http://localhost:8000/api/v1/owner/studios \
  -H "Authorization: Bearer OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Studio",
    "description": "Best studio in town",
    "address": "Jl. Sudirman No. 123",
    "city": "Jakarta",
    "province": "DKI Jakarta",
    "phone": "08123456789",
    "email": "studio@example.com"
  }'
```

### List Owner Bookings
```bash
curl http://localhost:8000/api/v1/owner/bookings \
  -H "Authorization: Bearer OWNER_TOKEN"
```

### Confirm Booking
```bash
curl -X POST http://localhost:8000/api/v1/owner/bookings/1/confirm \
  -H "Authorization: Bearer OWNER_TOKEN"
```

### Get Revenue
```bash
curl http://localhost:8000/api/v1/owner/revenue \
  -H "Authorization: Bearer OWNER_TOKEN"
```

---

## 👨‍💼 Admin Endpoints

> **Note:** Use admin_token from login as admin@studiobook.com

### Get Dashboard
```bash
curl http://localhost:8000/api/v1/admin/dashboard \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### List Users
```bash
curl http://localhost:8000/api/v1/admin/users \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### Get User Stats
```bash
curl http://localhost:8000/api/v1/admin/users/stats \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### List Studios
```bash
curl http://localhost:8000/api/v1/admin/studios \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### Verify Studio
```bash
curl -X POST http://localhost:8000/api/v1/admin/studios/1/verify \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### Activate User
```bash
curl -X POST http://localhost:8000/api/v1/admin/users/1/activate \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

---

## 🧪 Quick Test Script

Save this as `test_api.sh` and run it:

```bash
#!/bin/bash

BASE_URL="http://localhost:8000/api/v1"

echo "=== Testing StudioBook API ==="
echo ""

# Health Check
echo "1. Health Check"
curl -s "$BASE_URL/health" | jq .
echo ""

# Login as Customer
echo "2. Login as Customer"
TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@studiobook.com","password":"password"}' | jq -r '.data.token')
echo "Token: $TOKEN"
echo ""

# Login as Admin
echo "3. Login as Admin"
ADMIN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@studiobook.com","password":"password"}' | jq -r '.data.token')
echo "Admin Token: $ADMIN_TOKEN"
echo ""

# Get Profile
echo "4. Get Profile"
curl -s "$BASE_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# List Studios
echo "5. List Studios"
curl -s "$BASE_URL/studios?per_page=3" | jq .
echo ""

# List Bookings
echo "6. List Bookings"
curl -s "$BASE_URL/bookings" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

echo "=== Tests Complete ==="
```

Run with:
```bash
chmod +x test_api.sh
./test_api.sh
```

---

## 📝 Response Examples

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "errors": {
    "field": ["Error detail"]
  }
}
```

### Paginated Response
```json
{
  "success": true,
  "data": {
    "data": [...],
    "meta": {
      "current_page": 1,
      "last_page": 5,
      "per_page": 20,
      "total": 100
    }
  }
}
```
