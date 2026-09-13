#!/bin/bash

# ============================================
# Deploy StudioBook to InfinityFree
# ============================================

echo "🚀 StudioBook - Deploy to InfinityFree"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if .env.deploy exists
if [ ! -f ".env.deploy" ]; then
    echo -e "${RED}❌ File .env.deploy tidak ditemukan!${NC}"
    echo ""
    echo "Buat file .env.deploy dengan isi:"
    echo ""
    echo "FTP_HOST=ftpupload.net"
    echo "FTP_USER=your_ftp_username"
    echo "FTP_PASS=your_ftp_password"
    echo "API_URL=https://yourdomain.com"
    echo ""
    exit 1
fi

# Load environment
source .env.deploy

echo -e "${YELLOW}📋 Konfigurasi:${NC}"
echo "  FTP Host: $FTP_HOST"
echo "  FTP User: $FTP_USER"
echo "  API URL:  $API_URL"
echo ""

# Step 1: Build Frontend
echo -e "${YELLOW}📦 Building frontend...${NC}"
cd web

# Create production env
echo "VITE_API_URL=$API_URL/api/v1" > .env.production

# Build
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build gagal!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build berhasil!${NC}"
cd ..

# Step 2: Prepare Backend
echo -e "${YELLOW}📦 Preparing backend...${NC}"
cd backend

# Generate APP_KEY if not set
if grep -q "APP_KEY=$" .env 2>/dev/null || ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
    echo "Generating APP_KEY..."
    php artisan key:generate --force
fi

cd ..

# Step 3: Create deploy package
echo -e "${YELLOW}📦 Creating deploy package...${NC}"

# Create temp directory
DEPLOY_DIR="deploy-temp"
rm -rf $DEPLOY_DIR
mkdir -p $DEPLOY_DIR

# Copy frontend build
cp -r web/dist/* $DEPLOY_DIR/

# Copy backend
mkdir -p $DEPLOY_DIR/api
cp -r backend/app $DEPLOY_DIR/api/
cp -r backend/bootstrap $DEPLOY_DIR/api/
cp -r backend/config $DEPLOY_DIR/api/
cp -r backend/database $DEPLOY_DIR/api/
cp -r backend/resources $DEPLOY_DIR/api/
cp -r backend/routes $DEPLOY_DIR/api/
cp -r backend/storage $DEPLOY_DIR/api/
cp -r backend/vendor $DEPLOY_DIR/api/
cp backend/artisan $DEPLOY_DIR/api/
cp backend/composer.json $DEPLOY_DIR/api/
cp backend/.env $DEPLOY_DIR/api/

# Create root .htaccess
cat > $DEPLOY_DIR/.htaccess << 'EOF'
RewriteEngine On

# Handle API requests
RewriteCond %{REQUEST_URI} ^/api/(.*)$
RewriteRule ^api/(.*)$ /api/public/index.php?/$1 [L,QSA]

# Handle frontend (SPA)
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(?!api/)(?!assets/)(.*)$ /index.html [L]
EOF

echo -e "${GREEN}✅ Deploy package ready!${NC}"

# Step 4: Upload via FTP
echo -e "${YELLOW}📤 Uploading to InfinityFree...${NC}"

if command -v lftp &> /dev/null; then
    # Use lftp if available
    lftp -c "set ssl:verify-certificate no; open -u $FTP_USER,$FTP_PASS $FTP_HOST; mirror -R --delete $DEPLOY_DIR/ /public_html/; quit"
elif command -v ftp &> /dev/null; then
    echo -e "${RED}❌ Manual upload required. Gunakan FileZilla.${NC}"
    echo ""
    echo "Upload folder $DEPLOY_DIR/* ke /public_html/ di server."
else
    echo -e "${YELLOW}⚠️  FTP client tidak tersedia. Upload manual via FileZilla.${NC}"
    echo ""
    echo "📁 Folder yang perlu di-upload: $DEPLOY_DIR/"
    echo "📁 Upload ke: /public_html/"
fi

# Cleanup
rm -rf $DEPLOY_DIR

echo ""
echo -e "${GREEN}✅ Deploy selesai!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Cek website di browser"
echo "2. Jalankan migration: php artisan migrate"
echo "3. Jalankan seeder: php artisan db:seed"
echo "4. Test API: $API_URL/api/v1/health"
