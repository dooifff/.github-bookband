# 🚀 Deploy StudioBook ke Hostinger Shared Hosting

## ⚡ Quick Start (5 Langkah)

### Step 1: Generate APP_KEY
```bash
cd backend
composer install
php artisan key:generate --show
# Copy hasilnya, misal: base64:xxxxxxxxxxxxxxx
```

### Step 2: Build Frontend
```bash
cd web
npm install
npm run build
# Hasil build ada di web/dist/
```

### Step 3: Upload ke Hostinger
Buka **File Manager** di cPanel → masuk `public_html/`

Upload **SEMUA** file sesuai struktur ini:

```
public_html/
├── .htaccess                         ← dari deploy-hostinger/.htaccess
├── backend/
│   ├── .env                          ← BUAT BARU (lihat Step 4)
│   ├── app/
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   ├── routes/
│   ├── storage/
│   ├── vendor/                       ← hasil composer install
│   └── public/
│       ├── .htaccess                 ← dari backend/public/.htaccess
│       ├── index.php                 ← Laravel entry point
│       ├── index.html                ← dari web/dist/index.html
│       ├── router.php                ← BARU! PHP router
│       ├── setup.php                 ← diagnostic tool
│       ├── test.php                  ← server test
│       ├── login-test.html           ← login test page
│       ├── assets/                   ← dari web/dist/assets/
│       │   ├── index-xxxxx.css
│       │   └── index-xxxxx.js
│       └── favicon.svg               ← dari web/dist/ (jika ada)
```

### Step 4: Setup .env
Buat file `.env` di `public_html/backend/`:

```env
APP_NAME=StudioBook
APP_ENV=production
APP_KEY=base64:xxxxxxxxxxxxxxx
APP_DEBUG=false
APP_TIMEZONE=Asia/Jakarta
APP_URL=https://yourdomain.com

APP_LOCALE=id
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=id_ID

APP_MAINTENANCE_DRIVER=file

LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=u123456789_studiobook
DB_USERNAME=u123456789_admin
DB_PASSWORD=your_password

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database

CACHE_STORE=database
CACHE_PREFIX=studiobook

SANCTUM_STATEFUL_DOMAINS=yourdomain.com,www.yourdomain.com

FRONTEND_URL=https://yourdomain.com
ADMIN_URL=https://yourdomain.com

MIDTRANS_MERCHANT_ID=
MIDTRANS_CLIENT_KEY=
MIDTRANS_SERVER_KEY=
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_WEBHOOK_URL=https://yourdomain.com/api/v1/payments/webhook
```

### Step 5: Setup via Terminal cPanel
```bash
cd public_html/backend

# Install dependencies
composer install --no-dev --optimize-autoloader

# Generate key (jika belum)
php artisan key:generate

# Run migrations
php artisan migrate --force

# Seed database
php artisan db:seed --force

# Cache config & routes
php artisan config:cache
php artisan route:cache

# Fix permissions
chmod -R 775 storage
chmod -R 775 bootstrap/cache
```

### Step 6: Setup Cron Job
Di cPanel → **Cron Jobs**, tambahkan:
```
* * * * * cd /home/uXXXXXX/public_html/backend && php artisan schedule:run >> /dev/null 2>&1
```

---

## 🔍 Verifikasi Setup

Setelah deploy, buka URL ini untuk cek semuanya jalan:

1. **Health Check**: `https://yourdomain.com/api/health`
   - Harus return JSON: `{"success":true,"message":"StudioBook API is running"}`

2. **Setup Check**: `https://yourdomain.com/backend/public/setup.php`
   - Cek semua PASS (PHP version, APP_KEY, Database, Tables, dll)

3. **Server Test**: `https://yourdomain.com/backend/public/test.php`
   - Info lengkap tentang server

4. **Login Test**: Buka halaman login di website, coba login

**⚠️ HAPUS file `setup.php`, `test.php`, dan `login-test.html` setelah semuanya jalan!**

---

## 📁 File .htaccess

### File 1: `public_html/.htaccess` (ROOT)

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On

    # API routes → route through PHP router → Laravel
    RewriteCond %{REQUEST_URI} ^/(api|up)/
    RewriteRule ^ backend/public/router.php [L,QSA]

    # Static files from backend/public/ — serve directly
    RewriteCond %{DOCUMENT_ROOT}/backend/public%{REQUEST_URI} -f
    RewriteRule ^ - [L]

    # SPA fallback → React app via PHP router
    RewriteRule ^ backend/public/router.php [L,QSA]
</IfModule>

# Security
<IfModule mod_headers.c>
    <FilesMatch "\.(env|log|sqlite|db)$">
        Require all denied
    </FilesMatch>
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>

<FilesMatch "^\.">
    Require all denied
</FilesMatch>
```

### File 2: `public_html/backend/public/.htaccess`

```apache
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>
    RewriteEngine On
    RewriteCond %{REQUEST_URI} ^/api/
    RewriteRule ^ index.php [L]
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
<FilesMatch "\.(env|log|sqlite|db)$">
    Require all denied
</FilesMatch>
<FilesMatch "^\.">
    Require all denied
</FilesMatch>
```

---

## 🗄️ Database Setup di cPanel

1. Buka **MySQL Databases**
2. Buat database baru: `uXXXXX_studiobook`
3. Buat MySQL User dengan password kuat
4. Tambahkan user ke database → **All Privileges**

---

## 🔧 Troubleshooting

| Masalah | Solusi |
|---------|--------|
| **Login gagal / "Login failed"** | Buka `login-test.html` di browser untuk test detail |
| **500 Error** | Set `APP_DEBUG=true`, cek `storage/logs/laravel.log` |
| **API 404** | Pastikan file `.htaccess` dan `router.php` ada |
| **Database error** | Jalankan `php artisan migrate --force` |
| **CSS/JS tidak load** | Pastikan isi `web/dist/` diupload ke `backend/public/` |
| **APP_KEY kosong** | Jalankan `php artisan key:generate` |
| **"Class not found"** | Jalankan `composer install --no-dev` |
| **Permission denied** | `chmod -R 775 storage bootstrap/cache` |

---

## 📋 Pre-Deployment Checklist

- [ ] `public_html/.htaccess` sudah dibuat dengan benar
- [ ] `backend/public/.htaccess` sudah ada
- [ ] `backend/public/router.php` sudah di-upload
- [ ] `backend/.env` sudah dikonfigurasi lengkap
- [ ] `APP_KEY` sudah terisi (bukan kosong)
- [ ] `APP_URL=https://yourdomain.com` (bukan localhost)
- [ ] `FRONTEND_URL=https://yourdomain.com`
- [ ] `SANCTUM_STATEFUL_DOMAINS=yourdomain.com,www.yourdomain.com`
- [ ] Database sudah dibuat di cPanel
- [ ] `php artisan migrate --force` berhasil
- [ ] `php artisan db:seed --force` berhasil
- [ ] `composer install --no-dev` sudah dijalankan
- [ ] `php artisan config:cache` sudah dijalankan
- [ ] `php artisan route:cache` sudah dijalankan
- [ ] `storage/` dan `bootstrap/cache/` permission = 775
- [ ] PHP version >= 8.2 (cPanel → Select PHP Version)
- [ ] SSL sudah aktif (Let's Encrypt di Hostinger)
- [ ] Test `https://yourdomain.com/api/health` return JSON

---

**Last Updated:** September 2026
