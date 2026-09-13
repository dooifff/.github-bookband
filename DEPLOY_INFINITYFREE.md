# Deploy StudioBook ke InfinityFree

Panduan lengkap deploy aplikasi StudioBook ke hosting gratis InfinityFree.

## 📋 Persiapan

### Yang Perlu Disiapkan:
1. **Akun InfinityFree** - Daftar di https://infinityfree.net
2. **Domain** - Bisa pakai subdomain InfinityFree atau domain sendiri
3. **FileZilla** atau FTP client lainnya
4. **Terminal/Command Prompt** untuk build frontend

## 🚀 Langkah 1: Setup Akun InfinityFree

1. Login ke https://infinityfree.net
2. Klik **"Create Account"** atau **"Buat Akun"**
3. Pilih **PHP 8.x** (pastikan versi PHP minimal 8.1)
4. Buat **Database MySQL** di control panel:
   - Catat: **DB Host**, **DB Name**, **DB Username**, **DB Password**
5. Catat **FTP Host**, **FTP Username**, **FTP Password**

## 🚀 Langkah 2: Upload Backend (Laravel)

### Upload via FTP:
```
Host: ftpupload.net (atau ftp yang diberikan)
Username: (dari control panel)
Password: (dari control panel)
```

### Upload folder `backend/` ke public_html:
```
public_html/
├── app/
├── bootstrap/
├── config/
├── database/
├── public/         ← SYMLINK ke root
├── resources/
├── routes/
├── storage/
├── vendor/
├── artisan
├── .env
└── .htaccess
```

### ⚠️ Penting untuk InfinityFree:
InfinityFree menggunakan `public_html` sebagai document root. Kita perlu:
1. Upload semua file Laravel ke `public_html`
2. Atau lebih baik: upload ke subfolder dan symlink

### Cara Termudah:
Upload semua isi `backend/` ke `public_html/backend/` lalu buat `.htaccess` di root untuk redirect.

**Atau** (Recommended):
1. Upload isi `backend/public/*` ke `public_html/`
2. Upload folder `backend/` lainnya ke `public_html/app-root/`
3. Edit `public_html/index.php` untuk pointing ke `app-root`

## 🚀 Langkah 3: Build Frontend

```bash
# Di komputer lokal
cd web

# Set production API URL
echo "VITE_API_URL=https://domain-anda.com/api/v1" > .env.production

# Build
npm run build
```

## 🚀 Langkah 4: Upload Frontend

Upload isi `web/dist/` ke `public_html/`:
```
public_html/
├── index.html
├── assets/
│   ├── index-xxxx.js
│   └── index-xxxx.css
├── api/              ← Backend Laravel
│   ├── app/
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   ├── public/
│   ├── resources/
│   ├── routes/
│   ├── storage/
│   ├── vendor/
│   ├── artisan
│   └── .env
└── .htaccess
```

## 🚀 Langkah 5: Konfigurasi .htaccess

### File: `public_html/.htaccess`
```apache
RewriteEngine On

# Handle frontend routes (SPA)
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(?!api/)(?!assets/)(.*)$ /index.html [L]

# Proxy API requests to Laravel
RewriteCond %{REQUEST_URI} ^/api/(.*)$
RewriteRule ^api/(.*)$ /api/public/index.php?/$1 [L,QSA]
```

### File: `public_html/api/public/index.php` (sudah ada dari Laravel)

## 🚀 Langkah 6: Konfigurasi Backend

### Edit `.env` di server:
```env
APP_NAME=StudioBook
APP_ENV=production
APP_KEY=base64:xxx  # Generate dulu!
APP_DEBUG=false
APP_URL=https://domain-anda.com

DB_CONNECTION=mysql
DB_HOST=mysql.epizy.com  # Dari control panel InfinityFree
DB_DATABASE=epiz_xxxxxx  # Dari control panel
DB_USERNAME=epiz_xxxxxx  # Dari control panel
DB_PASSWORD=xxxxxx       # Dari control panel

SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database

SANCTUM_STATEFUL_DOMAINS=domain-anda.com

FRONTEND_URL=https://domain-anda.com
```

### Generate APP_KEY:
```bash
cd backend
php artisan key:generate
```
Copy hasilnya ke `.env` di server.

## 🚀 Langkah 7: Setup Database

### Via phpMyAdmin (di control panel InfinityFree):
1. Buka phpMyAdmin
2. Import database dari `backend/database/` atau jalankan migration

### Via terminal (jika SSH tersedia):
```bash
cd api  # folder backend
php artisan migrate --force
php artisan db:seed --force
```

### ⚠️ Tanpa SSH:
Gunakan **Laravel Database Seeder SQL** yang sudah di-export:
1. Export SQL dari local: `mysqldump -u root studiobook > backup.sql`
2. Import via phpMyAdmin di InfinityFree

## 🚀 Langkah 8: Set Permission

Folder yang perlu writable:
```
storage/
bootstrap/cache/
```

Set permission via FTP: **775** atau **755**

## 🔧 Troubleshooting

### Error 500:
- Cek `APP_DEBUG=true` sementara untuk lihat error
- Pastikan `storage/` writable
- Cek `vendor/` sudah di-upload lengkap

### API 404:
- Pastikan `.htaccess` benar
- Pastikan Laravel route berfungsi
- Coba akses `https://domain.com/api/v1/health`

### CORS Error:
- Set `SANCTUM_STATEFUL_DOMAINS` di `.env`
- Set `FRONTEND_URL` di `.env`

### Database Connection:
- Pastikan DB credentials benar
- Pastikan database sudah dibuat di control panel

## 📝 Checklist Deploy

- [ ] Akun InfinityFree dibuat
- [ ] Database MySQL dibuat
- [ ] Backend di-upload via FTP
- [ ] Frontend build dan upload
- [ ] `.env` dikonfigurasi
- [ ] `APP_KEY` di-generate
- [ ] Database di-import/migrate
- [ ] Permission folder set
- [ ] `.htaccess` dikonfigurasi
- [ ] Test API: `https://domain.com/api/v1/health`
- [ ] Test Frontend: `https://domain.com`
