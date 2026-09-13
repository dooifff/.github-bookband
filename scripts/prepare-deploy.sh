#!/bin/bash

# ============================================
# Prepare StudioBook for InfinityFree Deploy
# ============================================

echo "🚀 Preparing StudioBook for InfinityFree Deploy"
echo "================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create deploy directory
DEPLOY_DIR="studiobook-deploy"
rm -rf $DEPLOY_DIR
mkdir -p $DEPLOY_DIR

echo -e "${YELLOW}📦 Copying frontend build...${NC}"
cp -r web/dist/* $DEPLOY_DIR/

echo -e "${YELLOW}📦 Copying backend files...${NC}"
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
cp backend/.env.example $DEPLOY_DIR/api/.env

# Create api/public directory for Laravel
mkdir -p $DEPLOY_DIR/api/public
cp -r backend/public/* $DEPLOY_DIR/api/public/

# Create root .htaccess for InfinityFree
cat > $DEPLOY_DIR/.htaccess << 'EOF'
RewriteEngine On

# Handle API requests
RewriteCond %{REQUEST_URI} ^/api/(.*)$
RewriteRule ^api/(.*)$ /api/public/index.php?/$1 [L,QSA]

# Handle frontend (SPA)
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(?!api/)(?!assets/)(.*)$ /index.html [L]

# Handle Authorization Header
RewriteCond %{HTTP:Authorization} .
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
EOF

# Create api/.htaccess for Laravel
cat > $DEPLOY_DIR/api/.htaccess << 'EOF'
RewriteEngine On

# Redirect Trailing Slashes
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)/$ /$1 [L,R=301]

# Handle Front Controller
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ index.php [L]

# Handle Authorization Header
RewriteCond %{HTTP:Authorization} .
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
EOF

# Create api/public/.htaccess for Laravel
cat > $DEPLOY_DIR/api/public/.htaccess << 'EOF'
RewriteEngine On

# Redirect Trailing Slashes
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)/$ /$1 [L,R=301]

# Handle Front Controller
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ index.php [L]

# Handle Authorization Header
RewriteCond %{HTTP:Authorization} .
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
EOF

# Create README for deployment
cat > $DEPLOY_DIR/README.md << 'EOF'
# StudioBook - InfinityFree Deployment

## Upload Instructions

1. Upload ALL files in this folder to `public_html/` via FileZilla
2. Edit `api/.env` with your database credentials
3. Set permissions:
   - `api/storage/` → 775
   - `api/bootstrap/cache/` → 775
4. Import database via phpMyAdmin
5. Test: https://yourdomain.com/api/v1/health

## Database Setup

1. Create MySQL database in InfinityFree control panel
2. Edit `api/.env` with DB credentials
3. Import SQL file or run migration

## File Structure

```
public_html/
├── index.html          (Frontend)
├── assets/             (CSS/JS)
├── api/                (Backend Laravel)
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
EOF

echo -e "${GREEN}✅ Deploy package ready!${NC}"
echo ""
echo -e "${YELLOW}📁 Folder: $DEPLOY_DIR/${NC}"
echo ""
echo -e "${YELLOW}📤 Upload via FileZilla:${NC}"
echo "1. Host: ftpupload.net"
echo "2. Username: (dari control panel)"
echo "3. Password: (dari control panel)"
echo "4. Upload semua file ke /public_html/"
echo ""
echo -e "${YELLOW}📝 Setelah upload:${NC}"
echo "1. Edit api/.env (database credentials)"
echo "2. Set permission api/storage/ → 775"
echo "3. Import database via phpMyAdmin"
echo "4. Test website"
