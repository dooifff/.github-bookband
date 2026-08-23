# StudioBook Postman Collection

## 📁 Files

| File | Description |
|------|-------------|
| `StudioBook_API.postman_collection.json` | Main API collection (73 requests) |
| `StudioBook_Local.postman_environment.json` | Local development environment |
| `StudioBook_Staging.postman_environment.json` | Staging environment |
| `StudioBook_Production.postman_environment.json` | Production environment |

---

## 🚀 Quick Start

### 1. Import Collection

1. Open Postman
2. Click **Import** button (top left)
3. Select **File** tab
4. Choose `StudioBook_API.postman_collection.json`
5. Click **Import**

### 2. Import Environment

1. Click the **Environment** dropdown (top right)
2. Click **Import** 
3. Choose the appropriate environment file:
   - `StudioBook_Local.postman_environment.json` (for local dev)
   - `StudioBook_Staging.postman_environment.json` (for staging)
   - `StudioBook_Production.postman_environment.json` (for production)
4. Click **Import**

### 3. Select Environment

1. Click the **Environment** dropdown (top right)
2. Select **StudioBook - Local Development**

---

## 🔐 Authentication Workflow

### Step 1: Login as Customer

1. Open **Authentication** folder
2. Click **Login as Customer**
3. Click **Send**
4. Token is automatically saved to `token` variable

### Step 2: Login as Admin

1. Click **Login as Admin**
2. Click **Send**
3. Token is automatically saved to `admin_token` variable

### Step 3: Login as Owner

1. Click **Login as Owner**
2. Click **Send**
3. Token is automatically saved to `owner_token` variable

---

## 📋 Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `base_url` | API base URL | `http://localhost:8000/api/v1` |
| `token` | Customer auth token | (auto-populated) |
| `admin_token` | Admin auth token | (auto-populated) |
| `owner_token` | Owner auth token | (auto-populated) |
| `customer_email` | Customer email | `customer@studiobook.com` |
| `customer_password` | Customer password | `password` |
| `admin_email` | Admin email | `admin@studiobook.com` |
| `admin_password` | Admin password | `password` |
| `owner_email` | Owner email | `owner@studiobook.com` |
| `owner_password` | Owner password | `password` |
| `test_studio_slug` | Test studio slug | `studio-melody-1` |
| `test_studio_id` | Test studio ID | `1` |
| `test_room_id` | Test room ID | `1` |
| `test_booking_id` | Test booking ID | `1` |

---

## 🧪 Testing Workflow

### Public Endpoints (No Auth Required)

1. Open **Health Check** folder
2. Click **Health Check**
3. Click **Send**
4. Verify response: `{"success": true, "message": "StudioBook API is running"}`

### Customer Endpoints

1. First, login as customer (see Authentication Workflow)
2. Open **Studios** folder
3. Click **List Studios**
4. Click **Send**
5. Verify response contains studio data

### Owner Endpoints

1. First, login as owner (see Authentication Workflow)
2. Open **Owner - Dashboard** folder
3. Click **Get Dashboard**
4. Click **Send**
5. Verify response contains dashboard stats

### Admin Endpoints

1. First, login as admin (see Authentication Workflow)
2. Open **Admin - Dashboard** folder
3. Click **Get Dashboard**
4. Click **Send**
5. Verify response contains platform stats

---

## 📁 Collection Structure

```
StudioBook API
├── Health Check
│   └── Health Check
├── Authentication
│   ├── Register
│   ├── Login
│   ├── Login as Admin
│   ├── Login as Owner
│   ├── Get Profile
│   ├── Update Profile
│   ├── Change Password
│   └── Logout
├── Studios
│   ├── List Studios
│   ├── Search Studios
│   ├── Get Studio by Slug
│   ├── Get Studio Rooms
│   ├── Get Studio Equipment
│   ├── Get Studio Opening Hours
│   ├── Check Availability
│   └── Get Studio Reviews
├── Bookings
│   ├── List My Bookings
│   ├── Create Booking
│   ├── Get Booking Detail
│   ├── Get Booking by Code
│   └── Cancel Booking
├── Payments
│   ├── Create Payment
│   ├── Get Payment Status
│   └── Get Payment History
├── Favorites
│   ├── List Favorites
│   ├── Toggle Favorite
│   ├── Check Favorite Status
│   └── Remove Favorite
├── Reviews
│   ├── Create Review
│   ├── Get My Reviews
│   └── Delete Review
├── Bands
│   ├── List My Bands
│   ├── Create Band
│   ├── Get Band Detail
│   └── Invite Member
├── Notifications
│   ├── List Notifications
│   ├── Get Unread Count
│   └── Mark All as Read
├── Membership
│   ├── List Membership Plans
│   ├── Get Current Membership
│   ├── Subscribe to Plan
│   ├── Cancel Membership
│   └── Check Discount
├── Promos
│   ├── List Promos
│   └── Validate Promo Code
├── Referral
│   ├── Get Referral Info
│   ├── Get Referral Code
│   └── Validate Referral Code
├── Owner - Dashboard
│   ├── Get Dashboard
│   ├── Get Today's Stats
│   ├── Get Analytics
│   └── Get Revenue
├── Owner - Studios
│   ├── List My Studios
│   ├── Create Studio
│   ├── Update Studio
│   └── Delete Studio
├── Owner - Bookings
│   ├── List Owner Bookings
│   ├── Confirm Booking
│   └── Complete Booking
├── Admin - Dashboard
│   └── Get Dashboard
├── Admin - Users
│   ├── List Users
│   ├── Get User Stats
│   ├── Get User Detail
│   ├── Activate User
│   └── Deactivate User
├── Admin - Studios
│   ├── List Studios
│   ├── Get Studio Stats
│   ├── Get Pending Verifications
│   ├── Verify Studio
│   └── Activate Studio
└── Admin - Bookings
    ├── List Bookings
    └── Get Booking Stats
```

---

## 🔧 Troubleshooting

### Token Not Saved

If the token is not automatically saved after login:

1. Open the login request
2. Go to **Tests** tab
3. Verify the test script is present:
```javascript
var jsonData = pm.response.json();
if (jsonData.success && jsonData.data.token) {
    pm.collectionVariables.set('token', jsonData.data.token);
}
```

### 401 Unauthorized

1. Make sure you've logged in first
2. Check that the token variable is set
3. Verify the environment is selected

### 404 Not Found

1. Check the `base_url` variable
2. Verify the server is running
3. Check the endpoint URL

---

## 📚 Additional Resources

- [API Documentation](../docs/api.md)
- [API Test Commands](../API_TEST_COMMANDS.md)
- [API Endpoints Verification](../API_ENDPOINTS.md)
