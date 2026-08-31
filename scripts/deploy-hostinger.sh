#!/bin/bash
# =============================================================================
# STUDIOBOOK - Hostinger Shared Hosting Deployment Script
# =============================================================================
# Jalankan script ini di komputer lokal sebelum upload ke Hostinger
# =============================================================================

set -e

echo "🚀 StudioBook - Hostinger Deployment Helper"
echo "============================================="
echo ""

# Check PHP
if ! command -v php &> /dev/null; then
    echo "❌ PHP tidak ditemukan. Install PHP dulu atau gunakan: composer install"
    exit 1
fi

# Generate APP_KEY
echo "🔑 Generating APP_KEY..."
cd backend
KEY=$(php artisan key:generate --show 2>/dev/null)
echo ""
echo "✅ APP_KEY Generated:"
echo "   $KEY"
echo ""
echo "📋 Copy key ini dan paste ke .env di Hostinger:"
echo "   APP_KEY=$KEY"
echo ""

# Build frontend
echo "📦 Building frontend..."
cd ../web
if [ -f "package.json" ]; then
    npm install
    echo ""
    echo "⚠️  Penting: Buat file .env di folder web/ dulu!"
    echo "   Isi: VITE_API_URL=https://domainmu.com/api/v1"
    echo ""
    read -p "Masukkan domain production (contoh: studiobook.com): " DOMAIN
    echo "VITE_API_URL=https://$DOMAIN/api/v1" > .env
    echo "✅ File .env frontend dibuat"
    echo ""
    npm run build
    echo "✅ Frontend built ke web/dist/"
else
    echo "⚠️  package.json tidak ditemukan, skip frontend build"
fi

cd ..

echo ""
echo "============================================"
echo "📋 DEPLOYMENT CHECKLIST"
echo "============================================"
echo ""
echo "1️⃣  Database MySQL:"
echo "   - Login cPanel → MySQL Databases"
echo "   - Buat database: studiobook"
echo "   - Buat user & tambahkan ke database (All Privileges)"
echo "   - Catat: uXXXXX_studiobook, uXXXXX_admin"
echo ""
echo "2️⃣  Upload Files:"
echo "   - Buka File Manager di cPanel"
echo "   - Upload folder backend/ ke public_html/"
echo "   - Upload isi web/dist/ ke public_html/backend/public/"
echo ""
echo "3️⃣  Setup .env:"
echo "   - Copy .env.production.hostinger ke .env"
echo "   - Isi APP_KEY, DB credentials, domain, dll"
echo ""
echo "4️⃣  Install Composer:"
echo "   - Di Terminal cPanel: cd public_html/backend"
echo "   - composer install --no-dev --optimize-autoloader"
echo ""
echo "5️⃣  Setup Permissions:"
echo "   - Set storage/ ke 775 (recursive)"
echo "   - Set bootstrap/cache/ ke 775"
echo ""
echo "6️⃣  Create .htaccess:"
echo "   - Buat .htaccess di public_html/"
echo "   - Isi: RewriteRule ^(.*)$ backend/public/\$1 [L]"
echo ""
echo "7️⃣  Migrate Database:"
echo "   - php artisan migrate --force"
echo "   - php artisan config:cache"
echo "   - php artisan route:cache"
echo ""
echo "8️⃣  Setup Cron Job:"
echo "   - Di cPanel → Cron Jobs"
echo "   - * * * * * cd /home/uXXXXXX/public_html/backend && php artisan schedule:run"
echo ""
echo "✅ Selesai! Website siap online."
