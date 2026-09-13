# 🔧 FIX: Login Gagal di Hostinger (404 Not Found)

## Masalah
`.htaccess` rewrite rules **tidak jalan** di Hostinger. Ini masalah umum karena:
- Hostinger pakai LiteSpeed (bukan Apache)
- Atau `mod_rewrite` dinonaktifkan
- Atau `AllowOverride` diset ke `None`

## Solusi
Gunakan **PHP Router** di root — tidak perlu `.htaccess`!

---

## 📋 Langkah Fix (5 menit)

### Step 1: Upload file baru

Buka **File Manager** di cPanel, upload ini:

| File | Upload ke |
|------|-----------|
| `web/root-index.php` | `public_html/index.php` |
| `deploy-hostinger/.htaccess` | `public_html/.htaccess` |
| `backend/public/router.php` | `public_html/backend/public/router.php` |
| `backend/public/setup.php` | `public_html/backend/public/setup.php` |
| `backend/public/login-test.html` | `public_html/backend/public/login-test.html` |

**⚠️ PENTING: `root-index.php` harus di-rename jadi `index.php` saat upload!**

### Step 2: Cek apakah PHP Router jalan

Buka browser, akses:
```
https://yourdomain.com/api/health
```

**✅ Kalau muncul JSON** → Fix berhasil! Lanjut ke Step 4.
**❌ Kalau masih 404** → Lanjut ke Step 3.

### Step 3: Kalau PHP Router tidak jalan

Jika Step 2 masih 404, coba akses langsung:
```
https://yourdomain.com/backend/public/setup.php
```

Kalau ini jalan, berarti file sudah benar tapi routing belum bekerja.
Coba **Step 3b** di bawah.

#### Step 3b: Restructure files (lebih drastis)

Jika semua cara di atas gagal, pindahkan file ke root:

1. **Pindahkan isi `backend/` ke root `public_html/`:**
   ```
   public_html/
   ├── index.php              ← dari backend/public/index.php
   ├── .htaccess              ← Standard Laravel .htaccess
   ├── app/                   ← dari backend/app/
   ├── bootstrap/             ← dari backend/bootstrap/
   ├── config/                ← dari backend/config/
   ├── database/              ← dari backend/database/
   ├── routes/                ← dari backend/routes/
   ├── storage/               ← dari backend/storage/
   ├── vendor/                ← dari backend/vendor/
   ├── .env                   ← dari backend/.env
   └── ...
   ```

2. **Pindahkan React SPA ke root:**
   ```
   public_html/
   ├── index.html             ← dari backend/public/index.html
   ├── assets/                ← dari backend/public/assets/
   └── ...
   ```

3. **Upload `.htaccess` Laravel standar:**
   ```apache
   <IfModule mod_rewrite.c>
       <IfModule mod_negotiation.c>
           Options -MultiViews -Indexes
       </IfModule>
       RewriteEngine On
       RewriteCond %{REQUEST_FILENAME} !-d
       RewriteCond %{REQUEST_FILENAME} !-f
       RewriteRule ^ index.php [L]
   </IfModule>
   ```

4. **Test lagi:** `https://yourdomain.com/api/health`

### Step 4: Verifikasi Setup

Buka di browser:
```
https://yourdomain.com/backend/public/setup.php
```

Copy hasilnya dan kirim ke saya jika ada yang FAIL.

### Step 5: Test Login

Buka halaman login di website, coba login:
- Email: `admin@studiobook.com`
- Password: `password`

### Step 6: Hapus file debug

Setelah login berhasil, **HAPUS**:
- `setup.php`
- `test.php`
- `login-test.html`

---

## 🔍 Debug Commands (Terminal cPanel)

```bash
# Cek apakah .htaccess jalan
cd public_html
cat .htaccess
ls -la index.php

# Cek PHP version
php -v

# Cek apakah router.php ada
ls -la backend/public/router.php

# Test API langsung via curl
curl -s https://yourdomain.com/api/health

# Test login via curl
curl -s -X POST https://yourdomain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"admin@studiobook.com","password":"password"}'

# Cek error log
tail -50 backend/storage/logs/laravel.log
```

---

## ⚠️ Checklist

- [ ] `public_html/index.php` sudah di-upload (dari `root-index.php`)
- [ ] `public_html/.htaccess` sudah di-upload
- [ ] `public_html/backend/public/router.php` sudah ada
- [ ] `https://yourdomain.com/api/health` return JSON
- [ ] `https://yourdomain.com/backend/public/setup.php` semua PASS
- [ ] Login berhasil

---

**Last Updated:** September 2026
