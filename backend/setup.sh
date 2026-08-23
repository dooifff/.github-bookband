#!/bin/bash

# StudioBook Setup Script
# Automated setup for local development

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudioBook Development Setup                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed!${NC}"
    echo -e "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed!${NC}"
    echo -e "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"
echo ""

# Navigate to project root
cd "$(dirname "$0")/.."

# Copy environment files
echo -e "${YELLOW}Setting up environment files...${NC}"

if [ ! -f backend/.env ]; then
    cp backend/.env.example backend/.env
    echo -e "${GREEN}✓ Created backend/.env${NC}"
fi

# Generate app key
echo -e "${YELLOW}Generating application key...${NC}"
docker compose run --rm api php artisan key:generate --force 2>/dev/null || true
echo -e "${GREEN}✓ Application key generated${NC}"
echo ""

# Start Docker containers
echo -e "${YELLOW}Starting Docker containers...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Containers started${NC}"
echo ""

# Wait for MySQL to be ready
echo -e "${YELLOW}Waiting for MySQL to be ready...${NC}"
sleep 10
echo -e "${GREEN}✓ MySQL is ready${NC}"
echo ""

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
docker compose exec -T api php artisan migrate --force
echo -e "${GREEN}✓ Migrations completed${NC}"
echo ""

# Seed database
echo -e "${YELLOW}Seeding database with sample data...${NC}"
docker compose exec -T api php artisan db:seed --force
echo -e "${GREEN}✓ Database seeded${NC}"
echo ""

# Clear and cache config
echo -e "${YELLOW}Optimizing application...${NC}"
docker compose exec -T api php artisan config:cache
docker compose exec -T api php artisan route:cache
docker compose exec -T api php artisan view:cache
echo -e "${GREEN}✓ Application optimized${NC}"
echo ""

echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Setup completed successfully!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Services:${NC}"
echo -e "  Web:      ${BLUE}http://localhost${NC}"
echo -e "  API:      ${BLUE}http://localhost:8000/api/health${NC}"
echo -e "  phpMyAdmin: ${BLUE}http://localhost:8080${NC}"
echo -e "  Mailhog:  ${BLUE}http://localhost:8025${NC}"
echo ""
echo -e "${YELLOW}Test Accounts:${NC}"
echo -e "  Admin:    admin@studiobook.com / password"
echo -e "  Owner:    owner@studiobook.com / password"
echo -e "  Customer: customer@studiobook.com / password"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "  ${BLUE}docker compose up -d${NC}        Start containers"
echo -e "  ${BLUE}docker compose down${NC}         Stop containers"
echo -e "  ${BLUE}docker compose logs -f${NC}      View logs"
echo -e "  ${BLUE}docker compose exec api bash${NC} Access API shell"
echo -e "  ${BLUE}docker compose exec web bash${NC} Access Web shell"
echo ""
