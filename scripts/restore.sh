#!/bin/bash

# StudioBook Restore Script
# Restore from backup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="./backups"
COMPOSE_FILE="docker-compose.prod.yml"

# Check if backup name is provided
if [ -z "$1" ]; then
    echo -e "${RED}✗ Please provide backup name${NC}"
    echo -e "Usage: ${BLUE}./scripts/restore.sh <backup_name>${NC}"
    echo ""
    echo -e "Available backups:"
    ls -1 ${BACKUP_DIR} | grep studiobook_backup_ || echo "  No backups found"
    exit 1
fi

BACKUP_NAME="$1"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Check if backup exists
if [ ! -d "${BACKUP_PATH}" ]; then
    echo -e "${RED}✗ Backup not found: ${BACKUP_PATH}${NC}"
    exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudioBook Restore                               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Restoring from: ${YELLOW}${BACKUP_NAME}${NC}"
echo ""

# Confirm restore
echo -e "${RED}⚠ WARNING: This will overwrite the current database!${NC}"
read -p "Are you sure you want to continue? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi
echo ""

# Stop containers
echo -e "${YELLOW}Stopping containers...${NC}"
docker compose -f ${COMPOSE_FILE} down
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

# Start MySQL only
echo -e "${YELLOW}Starting MySQL...${NC}"
docker compose -f ${COMPOSE_FILE} up -d mysql
sleep 15
echo -e "${GREEN}✓ MySQL started${NC}"
echo ""

# Restore database
echo -e "${YELLOW}Restoring database...${NC}"
gunzip -c ${BACKUP_PATH}/database.sql.gz | docker compose -f ${COMPOSE_FILE} exec -T mysql mysql \
    -u root \
    -p${DB_ROOT_PASSWORD:-secret} \
    ${DB_DATABASE:-studiobook}
echo -e "${GREEN}✓ Database restored${NC}"
echo ""

# Restore storage
if [ -f "${BACKUP_PATH}/storage.tar.gz" ]; then
    echo -e "${YELLOW}Restoring storage files...${NC}"
    docker compose -f ${COMPOSE_FILE} up -d api
    sleep 5
    docker compose -f ${COMPOSE_FILE} exec -T api tar -xzf - -C / var/www/ < ${BACKUP_PATH}/storage.tar.gz 2>/dev/null || true
    docker compose -f ${COMPOSE_FILE} exec -T api chown -R www-data:www-data /var/www/storage
    echo -e "${GREEN}✓ Storage restored${NC}"
    echo ""
fi

# Restore configuration
if [ -f "${BACKUP_PATH}/env.backup" ]; then
    echo -e "${YELLOW}Restoring configuration...${NC}"
    cp ${BACKUP_PATH}/env.backup .env.production
    echo -e "${GREEN}✓ Configuration restored${NC}"
    echo ""
fi

# Start all containers
echo -e "${YELLOW}Starting all containers...${NC}"
docker compose -f ${COMPOSE_FILE} up -d
echo -e "${GREEN}✓ Containers started${NC}"
echo ""

# Wait for services
echo -e "${YELLOW}Waiting for services...${NC}"
sleep 30

# Run migrations (in case of schema changes)
echo -e "${YELLOW}Running migrations...${NC}"
docker compose -f ${COMPOSE_FILE} exec -T api php artisan migrate --force
echo -e "${GREEN}✓ Migrations completed${NC}"
echo ""

# Clear cache
echo -e "${YELLOW}Clearing cache...${NC}"
docker compose -f ${COMPOSE_FILE} exec -T api php artisan cache:clear
docker compose -f ${COMPOSE_FILE} exec -T api php artisan config:cache
docker compose -f ${COMPOSE_FILE} exec -T api php artisan route:cache
docker compose -f ${COMPOSE_FILE} exec -T api php artisan view:cache
echo -e "${GREEN}✓ Cache cleared and rebuilt${NC}"
echo ""

# Health check
echo -e "${YELLOW}Running health check...${NC}"
sleep 10

API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health || echo "000")
if [ "$API_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ API is healthy${NC}"
else
    echo -e "${RED}✗ API health check failed (HTTP ${API_HEALTH})${NC}"
fi

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Restore completed successfully!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Restored from:${NC}"
echo -e "  ${BLUE}${BACKUP_NAME}${NC}"
echo ""
echo -e "${YELLOW}Service URLs:${NC}"
echo -e "  Web:     ${BLUE}https://yourdomain.com${NC}"
echo -e "  API:     ${BLUE}https://yourdomain.com/api/health${NC}"
