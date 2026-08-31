# 🚀 Deploy StudioBook ke Hostinger Shared Hosting

## ⚡ Quick Start (5 Langkah)

### 1. Generate APP_KEY
```bash
cd backend
composer install
php artisan key:generate --show
# Copy hasilnya
```

### 2. Build Frontend
```bash
cd web
echo "VITE_API_URL=https://domainmu.com/api/v1" > .env
npm install
npm run build
# Hasil build ada di web/dist/
```

### 3. Upload ke Hostinger
Buka **File Manager** di cPanel, upload:
```
public_html/
├── backend/           ← upload seluruh folder backend
├── web/dist/*         ← upload isi dist/ ke backend/public/
└── .htaccess          ← buat baru (lihat bawah)
```

### 4. Setup .env
Copy `.env.production.hostinger` ke `.env`, isi:
- `APP_KEY` = hasil generate di step 1
- `DB_DATABASE` = `uXXXXX_studiobook` (dari cPanel)
- `DB_USERNAME` = `uXXXXX_admin` (dari cPanel)
- `DB_PASSWORD` = password database
- `APP_URL` = `https://domainmu.com`

### 5. Final Setup
Di Terminal cPanel:
```bash
cd public_html/backend
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache
php artisan route:cache
```

---

## 📁 File .htaccess

Buat file `.htaccess` di `public_html/`:

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteRule ^(.*)$ backend/public/$1 [L]
</IfModule>
```

---

## 🗄️ Database Setup di cPanel

1. Buka **MySQL Databases**
2. Buat database baru: `studiobook`
3. Buat MySQL User dengan password kuat
4. Tambahkan user ke database → **All Privileges**
5. Format nama: `uXXXXX_studiobook` (otomatis dari Hostinger)

---

## 📧 Mail Configuration

Di Hostinger, mail settings:
```env
MAIL_MAILER=smtp
MAIL_HOST=mail.domainmu.com
MAIL_PORT=587
MAIL_USERNAME=email@domainmu.com
MAIL_PASSWORD=password-email
MAIL_ENCRYPTION=tls
```

Atau gunakan Gmail SMTP:
```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your@gmail.com
MAIL_PASSWORD=app-password-gmail
MAIL_ENCRYPTION=tls
```

---

## ⏰ Cron Job (Scheduler)

Di cPanel → **Cron Jobs**, tambahkan:

```
* * * * * cd /home/uXXXXXX/public_html/backend && php artisan schedule:run >> /dev/null 2>&1
```

---

## 🔧 Troubleshooting

| Masalah | Solusi |
|---------|--------|
| **500 Error** | Set `APP_DEBUG=true` sementara, cek `storage/logs/laravel.log` |
| **CSS/JS tidak load** | Pastikan file `web/dist/` sudah diupload ke `public/` |
| **API 404** | Pastikan `.htaccess` benar dan mod_rewrite aktif |
| **Database error** | Cek format nama DB: `uXXXXX_nama` |
| **Session expired** | Pastikan `sessions` table sudah di-migrate |

---

## 📋 Pre-Deployment Checklist

- [ ] APP_KEY sudah di-generate
- [ ] Frontend sudah di-build (`npm run build`)
- [ ] `.env` sudah dikonfigurasi dengan benar
- [ ] Database sudah dibuat di cPanel
- [ ] File sudah diupload ke `public_html/`
- [ ] Composer dependencies sudah diinstall
- [ ] Permission `storage/` = 775
- [ ] Permission `bootstrap/cache/` = 775
- [ ] `.htaccess` sudah dibuat
- [ ] `php artisan migrate` sudah dijalankan
- [ ] Cron job sudah disetup
- [ ] Domain sudah mengarah ke hosting
- [ ] SSL sudah aktif (Let's Encrypt di Hostinger)

---

## 🔄 Update部署

Untuk update setelah perubahan code:

```bash
# 1. Build frontend
cd web && npm run build

# 2. Upload file yang berubah:
#    - web/dist/* → public_html/backend/public/
#    - backend/* → public_html/backend/

# 3. Di Terminal cPanel:
cd public_html/backend
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

**Last Updated:** August 2026
