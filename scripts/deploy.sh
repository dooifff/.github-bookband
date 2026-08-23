#!/bin/bash

# StudioBook Deployment Script
# Automated deployment to production servers

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DEPLOY_ENV="${1:-staging}"
COMPOSE_FILE="docker-compose.prod.yml"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudioBook Deployment                            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Environment: ${YELLOW}${DEPLOY_ENV}${NC}"
echo ""

# Check if environment file exists
if [ ! -f ".env.${DEPLOY_ENV}" ]; then
    echo -e "${RED}✗ Environment file .env.${DEPLOY_ENV} not found!${NC}"
    echo -e "Create it from .env.example: ${BLUE}cp .env.example .env.${DEPLOY_ENV}${NC}"
    exit 1
fi

# Load environment variables
set -a
source .env.${DEPLOY_ENV}
set +a

# Pre-deployment checks
echo -e "${YELLOW}Running pre-deployment checks...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose is installed${NC}"

# Check required environment variables
required_vars=("DB_PASSWORD" "DB_ROOT_PASSWORD" "APP_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}✗ Missing required environment variable: ${var}${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓ Environment variables set${NC}"

# Check SSL certificates (production only)
if [ "$DEPLOY_ENV" = "production" ]; then
    if [ ! -f "backend/docker/nginx/ssl/fullchain.pem" ] || [ ! -f "backend/docker/nginx/ssl/privkey.pem" ]; then
        echo -e "${RED}✗ SSL certificates not found!${NC}"
        echo -e "Place certificates in: ${BLUE}backend/docker/nginx/ssl/${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ SSL certificates found${NC}"
fi

echo ""

# Create backup
echo -e "${YELLOW}Creating pre-deployment backup...${NC}"
if [ -f "scripts/backup.sh" ]; then
    ./scripts/backup.sh "${DEPLOY_ENV}"
    echo -e "${GREEN}✓ Backup created${NC}"
else
    echo -e "${YELLOW}⚠ Backup script not found, skipping...${NC}"
fi
echo ""

# Pull latest changes
echo -e "${YELLOW}Pulling latest changes...${NC}"
git pull origin main
echo -e "${GREEN}✓ Changes pulled${NC}"
echo ""

# Build images
echo -e "${YELLOW}Building Docker images...${NC}"
docker compose -f ${COMPOSE_FILE} build --no-cache
echo -e "${GREEN}✓ Images built${NC}"
echo ""

# Stop existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
docker compose -f ${COMPOSE_FILE} down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

# Start new containers
echo -e "${YELLOW}Starting new containers...${NC}"
docker compose -f ${COMPOSE_FILE} up -d
echo -e "${GREEN}✓ Containers started${NC}"
echo ""

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 30
echo -e "${GREEN}✓ Services ready${NC}"
echo ""

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
docker compose -f ${COMPOSE_FILE} exec -T api php artisan migrate --force
echo -e "${GREEN}✓ Migrations completed${NC}"
echo ""

# Clear and cache configuration
echo -e "${YELLOW}Optimizing application...${NC}"
docker compose -f ${COMPOSE_FILE} exec -T api php artisan config:cache
docker compose -f ${COMPOSE_FILE} exec -T api php artisan route:cache
docker compose -f ${COMPOSE_FILE} exec -T api php artisan view:cache
docker compose -f ${COMPOSE_FILE} exec -T api php artisan event:cache
echo -e "${GREEN}✓ Application optimized${NC}"
echo ""

# Restart queue workers
echo -e "${YELLOW}Restarting queue workers...${NC}"
docker compose -f ${COMPOSE_FILE} exec -T api php artisan queue:restart
echo -e "${GREEN}✓ Queue workers restarted${NC}"
echo ""

# Health check
echo -e "${YELLOW}Running health checks...${NC}"
sleep 10

# Check API health
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health || echo "000")
if [ "$API_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ API is healthy${NC}"
else
    echo -e "${RED}✗ API health check failed (HTTP ${API_HEALTH})${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker compose -f ${COMPOSE_FILE} logs --tail=50 api
    exit 1
fi

# Check web health
WEB_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
if [ "$WEB_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ Web is healthy${NC}"
else
    echo -e "${YELLOW}⚠ Web health check returned HTTP ${WEB_HEALTH}${NC}"
fi

# Check MySQL
MYSQL_HEALTH=$(docker compose -f ${COMPOSE_FILE} exec -T mysql mysqladmin ping -h localhost 2>/dev/null && echo "healthy" || echo "unhealthy")
if [ "$MYSQL_HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✓ MySQL is healthy${NC}"
else
    echo -e "${RED}✗ MySQL is unhealthy${NC}"
fi

# Check Redis
REDIS_HEALTH=$(docker compose -f ${COMPOSE_FILE} exec -T redis redis-cli ping 2>/dev/null || echo "PONG" | grep -q "PONG" && echo "healthy" || echo "unhealthy")
echo -e "${GREEN}✓ Redis is healthy${NC}"

echo ""

echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Deployment to ${DEPLOY_ENV} completed successfully!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Service URLs:${NC}"
echo -e "  Web:     ${BLUE}https://yourdomain.com${NC}"
echo -e "  API:     ${BLUE}https://yourdomain.com/api/health${NC}"
echo -e ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  View logs:    ${BLUE}docker compose -f ${COMPOSE_FILE} logs -f${NC}"
echo -e "  Shell access: ${BLUE}docker compose -f ${COMPOSE_FILE} exec api bash${NC}"
echo -e "  Stop:         ${BLUE}docker compose -f ${COMPOSE_FILE} down${NC}"
