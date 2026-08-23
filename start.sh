#!/bin/bash

# ============================================
# StudioBook - Quick Start Script
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║        🎸  StudioBook - Music Studio Booking Platform       ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed!${NC}"
    echo -e "  Install: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓ Docker installed${NC}"

if ! docker compose version &> /dev/null 2>&1 && ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed!${NC}"
    echo -e "  Install: https://docs.docker.com/compose/install/"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose installed${NC}"

echo ""

# Menu
echo -e "${YELLOW}Select an option:${NC}"
echo ""
echo "  1) 🚀 Full Setup (fresh install)"
echo "  2) ▶️  Start Services"
echo "  3) ⏹️  Stop Services"
echo "  4) 🔄 Restart Services"
echo "  5) 📊 View Status"
echo "  6) 📋 View Logs"
echo "  7) 🗄️  Reset Database"
echo "  8) 🛠️  Open API Shell"
echo "  9) 📧 Send Test Report"
echo "  0) ❌ Exit"
echo ""
read -p "Enter your choice [1-9]: " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════${NC}"
        echo -e "${BLUE}     Full Setup - Fresh Installation${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════${NC}"
        echo ""
        
        # Copy env file
        if [ ! -f .env ]; then
            cp .env.example .env 2>/dev/null || cat > .env << 'EOF'
APP_NAME=StudioBook
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=studiobook
DB_USERNAME=studiobook
DB_PASSWORD=secret

REDIS_HOST=redis
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=noreply@studiobook.com
MAIL_FROM_NAME="StudioBook"
EOF
            echo -e "${GREEN}✓ Created .env file${NC}"
        fi
        
        # Build and start containers
        echo -e "${YELLOW}Building Docker containers...${NC}"
        docker compose build --no-cache
        echo -e "${GREEN}✓ Containers built${NC}"
        
        echo -e "${YELLOW}Starting services...${NC}"
        docker compose up -d
        echo -e "${GREEN}✓ Services started${NC}"
        
        # Wait for MySQL
        echo -e "${YELLOW}Waiting for MySQL to be ready...${NC}"
        sleep 15
        
        # Generate app key
        echo -e "${YELLOW}Generating application key...${NC}"
        docker compose exec -T api php artisan key:generate --force
        echo -e "${GREEN}✓ App key generated${NC}"
        
        # Run migrations
        echo -e "${YELLOW}Running migrations...${NC}"
        docker compose exec -T api php artisan migrate --force
        echo -e "${GREEN}✓ Migrations completed${NC}"
        
        # Seed database
        echo -e "${YELLOW}Seeding database...${NC}"
        docker compose exec -T api php artisan db:seed --force
        echo -e "${GREEN}✓ Database seeded${NC}"
        
        # Cache config
        echo -e "${YELLOW}Caching configuration...${NC}"
        docker compose exec -T api php artisan config:cache
        docker compose exec -T api php artisan route:cache
        echo -e "${GREEN}✓ Configuration cached${NC}"
        
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo -e "${GREEN}     ✅ Setup Complete!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo ""
        show_urls
        show_accounts
        ;;
    
    2)
        echo -e "${YELLOW}Starting services...${NC}"
        docker compose up -d
        echo -e "${GREEN}✓ Services started${NC}"
        show_urls
        ;;
    
    3)
        echo -e "${YELLOW}Stopping services...${NC}"
        docker compose down
        echo -e "${GREEN}✓ Services stopped${NC}"
        ;;
    
    4)
        echo -e "${YELLOW}Restarting services...${NC}"
        docker compose restart
        echo -e "${GREEN}✓ Services restarted${NC}"
        ;;
    
    5)
        echo -e "${BLUE}Service Status:${NC}"
        echo ""
        docker compose ps
        ;;
    
    6)
        echo -e "${YELLOW}Viewing logs (Ctrl+C to exit)...${NC}"
        docker compose logs -f
        ;;
    
    7)
        echo -e "${RED}⚠️  This will delete all data!${NC}"
        read -p "Are you sure? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo -e "${YELLOW}Resetting database...${NC}"
            docker compose exec -T api php artisan migrate:fresh --seed --force
            echo -e "${GREEN}✓ Database reset complete${NC}"
        fi
        ;;
    
    8)
        echo -e "${YELLOW}Opening API shell...${NC}"
        docker compose exec api bash
        ;;
    
    9)
        echo -e "${YELLOW}Sending test report...${NC}"
        docker compose exec -T api php artisan performance:send-reports --type=weekly --recipient=admin@studiobook.com
        ;;
    
    0)
        echo -e "${GREEN}Goodbye! 👋${NC}"
        exit 0
        ;;
    
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
esac

echo ""

show_urls() {
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}     🌐 Service URLs${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  📱 Web App:      ${GREEN}http://localhost${NC}"
    echo -e "  🔌 API:          ${GREEN}http://localhost:8000/api/health${NC}"
    echo -e "  🗄️  phpMyAdmin:   ${GREEN}http://localhost:8080${NC}"
    echo -e "  📧 Mailhog:      ${GREEN}http://localhost:8025${NC}"
    echo ""
}

show_accounts() {
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}     👤 Test Accounts${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Admin:    ${GREEN}admin@studiobook.com${NC} / password"
    echo -e "  Owner:    ${GREEN}owner@studiobook.com${NC} / password"
    echo -e "  Customer: ${GREEN}customer@studiobook.com${NC} / password"
    echo ""
}
