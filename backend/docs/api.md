# StudioBook API Documentation

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication
All protected endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer {token}
```

## Response Format

### Success Response
```json
{
  "success": true,
  "message": "Success message",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "errors": { ... }
}
```

---

## Authentication Endpoints

### Register
```
POST /auth/register
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "08123456789",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer"
    },
    "token": "1|abc123..."
  }
}
```

### Login
```
POST /auth/login
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer"
    },
    "token": "1|abc123..."
  }
}
```

### Logout
```
POST /auth/logout
```

**Headers:** `Authorization: Bearer {token}`

**Response (200):**
```json
{
  "success": true,
  "message": "Logout berhasil"
}
```

### Get Profile
```
GET /auth/me
```

**Headers:** `Authorization: Bearer {token}`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer",
    "phone": "08123456789"
  }
}
```

### Update Profile
```
PUT /auth/profile
```

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "phone": "08987654321"
}
```

### Update Password
```
PUT /auth/password
```

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "current_password": "oldpassword",
  "password": "newpassword",
  "password_confirmation": "newpassword"
}
```

---

## Studio Endpoints

### List Studios (Public)
```
GET /studios
```

**Query Parameters:**
- `search` - Search by name, city, or address
- `city` - Filter by city
- `province` - Filter by province
- `min_rating` - Minimum rating
- `min_price` - Minimum price per hour
- `max_price` - Maximum price per hour
- `sort` - Sort by: name, rating, created_at, total_reviews
- `order` - Order: asc, desc
- `per_page` - Items per page (default: 20, max: 50)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "name": "Studio Musik Jaya",
        "slug": "studio-musik-jaya",
        "city": "Jakarta",
        "province": "DKI Jakarta",
        "address": "Jl. Sudirman No. 123",
        "average_rating": 4.5,
        "total_reviews": 128,
        "rooms_count": 3
      }
    ],
    "links": { ... },
    "meta": { ... }
  }
}
```

### Get Studio by Slug
```
GET /studios/{slug}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Studio Musik Jaya",
    "slug": "studio-musik-jaya",
    "description": "Best studio in town",
    "address": "Jl. Sudirman No. 123",
    "city": "Jakarta",
    "province": "DKI Jakarta",
    "latitude": -6.2088,
    "longitude": 106.8456,
    "phone": "08123456789",
    "email": "studio@example.com",
    "is_active": true,
    "is_verified": true,
    "average_rating": 4.5,
    "total_reviews": 128,
    "rooms": [...],
    "equipment": [...],
    "opening_hours": [...],
    "images": [...]
  }
}
```

### Get Studio Rooms
```
GET /studios/{slug}/rooms
```

### Get Studio Equipment
```
GET /studios/{slug}/equipment
```

### Get Studio Opening Hours
```
GET /studios/{slug}/opening-hours
```

### Check Availability
```
GET /studios/{slug}/availability
```

**Query Parameters:**
- `date` - Date (YYYY-MM-DD)
- `start_time` - Start time (HH:MM)
- `end_time` - End time (HH:MM)
- `room_id` - Room ID (optional)

---

## Booking Endpoints (Protected)

### Create Booking
```
POST /bookings
```

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "studio_id": 1,
  "room_id": 1,
  "booking_date": "2025-03-15",
  "start_time": "10:00",
  "end_time": "12:00",
  "notes": "Need extra microphones"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Booking berhasil dibuat",
  "data": {
    "id": 1,
    "booking_code": "BK123456",
    "status": "pending",
    "total_amount": 100000,
    "booking_date": "2025-03-15",
    "start_time": "10:00",
    "end_time": "12:00"
  }
}
```

### List My Bookings
```
GET /bookings
```

**Query Parameters:**
- `status` - Filter by status
- `page` - Page number

### Get Booking Detail
```
GET /bookings/{id}
```

### Get Booking by Code
```
GET /bookings/code/{code}
```

### Cancel Booking
```
POST /bookings/{id}/cancel
```

---

## Payment Endpoints (Protected)

### Create Payment
```
POST /payments
```

**Request Body:**
```json
{
  "booking_id": 1,
  "payment_method": "bank_transfer",
  "bank_code": "bca"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Pembayaran berhasil dibuat",
  "data": {
    "id": 1,
    "payment_code": "PAY123456789",
    "amount": 100000,
    "status": "pending",
    "payment_url": "https://example.com/pay/..."
  }
}
```

### Check Payment Status
```
GET /payments/{paymentCode}/status
```

### Get Payment History
```
GET /payment-history
```

---

## Favorite Endpoints (Protected)

### Toggle Favorite
```
POST /favorites/toggle
```

**Request Body:**
```json
{
  "studio_id": 1
}
```

### List Favorites
```
GET /favorites
```

### Check Favorite Status
```
GET /favorites/check/{studioId}
```

---

## Review Endpoints

### List Studio Reviews (Public)
```
GET /studios/{slug}/reviews
```

### Create Review (Protected)
```
POST /reviews
```

**Request Body:**
```json
{
  "reviewable_type": "studio",
  "reviewable_id": 1,
  "booking_id": 1,
  "rating": 5,
  "comment": "Great studio!"
}
```

### Get My Reviews (Protected)
```
GET /reviews/my-reviews
```

### Delete Review (Protected)
```
DELETE /reviews/{id}
```

---

## Band Endpoints (Protected)

### List My Bands
```
GET /bands
```

### Create Band
```
POST /bands
```

**Request Body:**
```json
{
  "name": "My Band",
  "description": "Rock band",
  "genre": "Rock"
}
```

### Get Band Detail
```
GET /bands/{id}
```

### Update Band
```
PUT /bands/{id}
```

### Delete Band
```
DELETE /bands/{id}
```

### Invite Member
```
POST /bands/{id}/invite
```

**Request Body:**
```json
{
  "email": "member@example.com",
  "role": "guitarist"
}
```

---

## Owner Dashboard Endpoints (Protected, Role: Owner)

### Get Dashboard
```
GET /owner/dashboard
```

### Get Analytics
```
GET /owner/analytics
```

### Get Revenue Report
```
GET /owner/revenue
```

### Export Revenue Report (PDF)
```
GET /owner/revenue/export-pdf
```

**Query Parameters:**
- `start_date` - Start date (YYYY-MM-DD)
- `end_date` - End date (YYYY-MM-DD)

### Export Daily Report (PDF)
```
GET /owner/revenue/export-daily-pdf
```

**Query Parameters:**
- `date` - Report date (YYYY-MM-DD)

### Export Booking Summary (PDF)
```
GET /owner/revenue/export-bookings-pdf
```

**Query Parameters:**
- `start_date` - Start date (YYYY-MM-DD)
- `end_date` - End date (YYYY-MM-DD)
- `status` - Filter by status (optional)

### Export Booking Invoice (PDF)
```
GET /bookings/{id}/invoice
```

### Export Revenue Report (Excel)
```
GET /owner/revenue/export-excel
```

**Query Parameters:**
- `start_date` - Start date (YYYY-MM-DD)
- `end_date` - End date (YYYY-MM-DD)

### Export Booking Report (Excel)
```
GET /owner/revenue/export-bookings-excel
```

**Query Parameters:**
- `start_date` - Start date (YYYY-MM-DD)
- `end_date` - End date (YYYY-MM-DD)
- `status` - Filter by status (optional)

### Export Daily Revenue (Excel)
```
GET /owner/revenue/export-daily-excel
```

**Query Parameters:**
- `date` - Report date (YYYY-MM-DD)

### Export Customer List (Excel)
```
GET /owner/revenue/export-customers-excel
```

---

## Bulk Schedule Management (Protected, Role: Owner)

### Block Multiple Dates
```
POST /bulk-schedules/block-dates
```

**Request Body:**
```json
{
  "room_id": 1,
  "dates": ["2024-01-20", "2024-01-21", "2024-01-22"],
  "reason": "Maintenance"
}
```

### Block Date Range
```
POST /bulk-schedules/block-range
```

**Request Body:**
```json
{
  "room_id": 1,
  "start_date": "2024-01-20",
  "end_date": "2024-01-31",
  "start_time": "09:00",
  "end_time": "17:00",
  "reason": "Renovasi"
}
```

### Block Recurring Schedule (Weekly)
```
POST /bulk-schedules/block-recurring
```

**Request Body:**
```json
{
  "room_id": 1,
  "days_of_week": [0, 6],
  "start_date": "2024-01-20",
  "end_date": "2024-06-30",
  "reason": "Libur weekend"
}
```

### Block Multiple Rooms
```
POST /bulk-schedules/block-multiple-rooms
```

**Request Body:**
```json
{
  "room_ids": [1, 2, 3],
  "dates": ["2024-01-20", "2024-01-21"],
  "reason": "Event khusus"
}
```

### Remove Bulk Blocked Schedules
```
POST /bulk-schedules/remove-bulk
```

**Request Body:**
```json
{
  "blocked_ids": [1, 2, 3]
}
```

### Remove Blocked Schedules by Date Range
```
POST /bulk-schedules/remove-by-range
```

**Request Body:**
```json
{
  "room_id": 1,
  "start_date": "2024-01-20",
  "end_date": "2024-01-31"
}
```

### Get Blocked Schedules Summary
```
GET /bulk-schedules/summary
```

**Query Parameters:**
- `room_id` - Room ID (required)
- `start_date` - Start date (required)
- `end_date` - End date (required)

---

## Dynamic Pricing (Protected, Role: Owner)

### Get Pricing Rules
```
GET /pricing-rules?room_id=1
```

### Create Pricing Rule
```
POST /pricing-rules
```

**Request Body:**
```json
{
  "room_id": 1,
  "name": "Weekend Premium",
  "description": "Harga naik 50% di weekend",
  "multiplier": 1.5,
  "priority": 10,
  "days_of_week": [0, 6],
  "start_time": "09:00",
  "end_time": "22:00",
  "is_active": true
}
```

### Update Pricing Rule
```
PUT /pricing-rules/{id}
```

### Delete Pricing Rule
```
DELETE /pricing-rules/{id}
```

### Create Peak Hour Rules (Default)
```
POST /pricing/peak-hour-rules
```

**Request Body:**
```json
{
  "room_id": 1
}
```

---

## Public Pricing Routes

### Calculate Price
```
POST /pricing/calculate
```

**Request Body:**
```json
{
  "room_id": 1,
  "date": "2024-01-20",
  "start_time": "10:00",
  "end_time": "14:00"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "base_price": 100000,
    "hourly_price": 120000,
    "hours": 4,
    "total_price": 480000,
    "multiplier": 1.2,
    "applied_rules": [
      {
        "rule_id": 1,
        "name": "Weekend Premium",
        "multiplier": 1.2,
        "description": "Harga naik 20% di weekend"
      }
    ],
    "discount": 0,
    "surcharge": 80000
  }
}
```

### Get Pricing Preview
```
GET /pricing/preview?room_id=1&start_date=2024-01-20&end_date=2024-01-26
```

---

## Referral System (Protected)

### Get Referral Info
```
GET /referral
```

**Response:**
```json
{
  "success": true,
  "data": {
    "stats": {
      "code": "ABC12345",
      "total_referrals": 5,
      "total_earned": 250000,
      "pending_earned": 50000,
      "referred_users": [...]
    },
    "referral_link": "https://studiobook.com/register?ref=ABC12345",
    "credits": 250000
  }
}
```

### Get Referral Code
```
GET /referral/code
```

### Validate Referral Code
```
POST /referral/validate
```

**Request Body:**
```json
{
  "code": "ABC12345"
}
```

### Get Leaderboard
```
GET /referral/leaderboard
```

---

## Chat System (Protected)

### Get Chat Rooms
```
GET /chat
```

### Create Chat Room for Booking
```
POST /chat/rooms
```

**Request Body:**
```json
{
  "booking_id": 1
}
```

### Create General Chat Room
```
POST /chat/rooms/general
```

**Request Body:**
```json
{
  "studio_id": 1
}
```

### Get Messages
```
GET /chat/rooms/{roomId}/messages?page=1&limit=50
```

### Send Message
```
POST /chat/rooms/{roomId}/messages
```

**Request Body:**
```json
{
  "message": "Halo, apakah studio masih buka?",
  "type": "text"
}
```

### Mark as Read
```
POST /chat/rooms/{roomId}/read
```

### Close Chat Room
```
POST /chat/rooms/{roomId}/close
```

### Get Unread Count
```
GET /chat/unread-count
```

---

## Photo Reviews (Protected)

### Add Images to Review
```
POST /reviews/{reviewId}/images
```

**Request Body (multipart/form-data):**
- `images[]` - Array of images (max 5, max 5MB each)
- `captions[]` - Optional array of captions

### Remove Review Image
```
DELETE /reviews/images/{imageId}
```

---

## Admin Dashboard Endpoints (Protected, Role: Admin)

### Get Dashboard Stats
```
GET /admin/dashboard
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_users": 150,
    "total_studios": 25,
    "total_bookings": 500,
    "total_revenue": 75000000,
    "recent_bookings": [...],
    "recent_users": [...]
  }
}
```

### List Users
```
GET /admin/users
```

**Query Parameters:**
- `search` - Search by name or email
- `role` - Filter by role
- `page` - Page number

### Get User Stats
```
GET /admin/users/stats
```

### Get User Detail
```
GET /admin/users/{id}
```

### Update User
```
PUT /admin/users/{id}
```

### Activate User
```
POST /admin/users/{id}/activate
```

### Deactivate User
```
POST /admin/users/{id}/deactivate
```

### List Studios
```
GET /admin/studios
```

**Query Parameters:**
- `search` - Search by name or city
- `is_verified` - Filter by verification status
- `is_active` - Filter by active status
- `city` - Filter by city

### Get Studio Stats
```
GET /admin/studios/stats
```

### Get Pending Verifications
```
GET /admin/studios/pending
```

### Get Studio Detail
```
GET /admin/studios/{id}
```

### Verify Studio
```
POST /admin/studios/{id}/verify
```

### Unverify Studio
```
POST /admin/studios/{id}/unverify
```

### Activate Studio
```
POST /admin/studios/{id}/activate
```

### Deactivate Studio
```
POST /admin/studios/{id}/deactivate
```

### List Bookings
```
GET /admin/bookings
```

**Query Parameters:**
- `status` - Filter by status
- `page` - Page number

### Get Booking Stats
```
GET /admin/bookings/stats
```

### Get Booking Detail
```
GET /admin/bookings/{id}
```

---

## Notification Endpoints (Protected)

### List Notifications
```
GET /notifications
```

**Query Parameters:**
- `type` - Filter by type (booking, payment, promo, system)
- `is_read` - Filter by read status (true/false)
- `page` - Page number

### Mark Notification as Read
```
POST /notifications/{id}/read
```

### Mark All Notifications as Read
```
POST /notifications/read-all
```

### Delete Notification
```
DELETE /notifications/{id}
```

### Delete All Notifications
```
DELETE /notifications
```

### Get Unread Count
```
GET /notifications/unread-count
```

**Response:**
```json
{
  "success": true,
  "data": {
    "unread_count": 5
  }
}
```

### Store FCM Token
```
POST /notifications/fcm-token
```

**Request Body:**
```json
{
  "fcm_token": "device_fcm_token_here"
}
```

---

## Membership Endpoints (Protected)

### List Membership Plans
```
GET /membership/plans
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Silver Member",
      "description": "Basic membership",
      "price": 49000,
      "formatted_price": "Rp 49.000/month",
      "duration_days": 30,
      "benefits": ["Diskon 5%", "Prioritas CS"]
    }
  ]
}
```

### Get Current Membership
```
GET /membership/current
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "plan": {
      "id": 1,
      "name": "Silver Member",
      "benefits": ["Diskon 5%"]
    },
    "status": "active",
    "started_at": "2025-01-01T00:00:00.000000Z",
    "expires_at": "2025-02-01T00:00:00.000000Z",
    "days_remaining": 15
  }
}
```

### Subscribe to Plan
```
POST /membership/subscribe
```

**Request Body:**
```json
{
  "plan_id": 1
}
```

### Cancel Membership
```
POST /membership/cancel
```

### Get Membership History
```
GET /membership/history
```

### Check Discount
```
GET /membership/discount
```

**Response:**
```json
{
  "success": true,
  "data": {
    "has_discount": true,
    "discount_percentage": 5,
    "expires_at": "2025-02-01T00:00:00.000000Z"
  }
}
```

---

## Promo Endpoints (Protected)

### List Active Promos
```
GET /promos
```

### Validate Promo Code
```
POST /promos/validate
```

**Request Body:**
```json
{
  "code": "WEEKEND10",
  "booking_amount": 200000
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "code": "WEEKEND10",
    "name": "Weekend Discount",
    "type": "percentage",
    "value": 10,
    "discount_amount": 20000,
    "final_amount": 180000
  }
}
```

### Get Promo Detail
```
GET /promos/{code}
```

---

## Error Codes

| Code | Description |
|------|-------------|
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Validation Error |
| 429 | Too Many Requests |
| 500 | Server Error |

---

## Rate Limiting

- **Public endpoints:** 60 requests per minute
- **Authenticated endpoints:** 120 requests per minute
- **Login/Register:** 10 requests per minute

Rate limit headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
```

---

## Pagination

All list endpoints support pagination:

**Query Parameters:**
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 20, max: 50)

**Response:**
```json
{
  "data": {
    "data": [...],
    "links": {
      "first": "...",
      "last": "...",
      "prev": null,
      "next": "..."
    },
    "meta": {
      "current_page": 1,
      "from": 1,
      "last_page": 5,
      "path": "...",
      "per_page": 20,
      "to": 20,
      "total": 100
    }
  }
}
```
