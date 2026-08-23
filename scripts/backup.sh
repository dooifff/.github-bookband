#!/bin/bash

# StudioBook Backup Script
# Automated database and file backups

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
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="studiobook_backup_${DATE}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudioBook Backup                                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create backup directory
mkdir -p ${BACKUP_DIR}
mkdir -p ${BACKUP_DIR}/${BACKUP_NAME}

# Database backup
echo -e "${YELLOW}Creating database backup...${NC}"
docker compose -f ${COMPOSE_FILE} exec -T mysql mysqldump \
    -u root \
    -p${DB_ROOT_PASSWORD:-secret} \
    ${DB_DATABASE:-studiobook} \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    | gzip > ${BACKUP_DIR}/${BACKUP_NAME}/database.sql.gz
echo -e "${GREEN}✓ Database backup created${NC}"

# Storage backup
echo -e "${YELLOW}Creating storage backup...${NC}"
docker compose -f ${COMPOSE_FILE} exec -T api tar -czf - storage/app/public \
    > ${BACKUP_DIR}/${BACKUP_NAME}/storage.tar.gz 2>/dev/null || true
echo -e "${GREEN}✓ Storage backup created${NC}"

# Configuration backup
echo -e "${YELLOW}Creating configuration backup...${NC}"
cp .env.${1:-production} ${BACKUP_DIR}/${BACKUP_NAME}/env.backup 2>/dev/null || true
cp docker-compose.prod.yml ${BACKUP_DIR}/${BACKUP_NAME}/
echo -e "${GREEN}✓ Configuration backup created${NC}"

# Create manifest
cat > ${BACKUP_DIR}/${BACKUP_NAME}/manifest.txt << EOF
Backup Date: $(date)
Environment: ${1:-production}
Database: ${DB_DATABASE:-studiobook}
Files:
  - database.sql.gz (Database dump)
  - storage.tar.gz (Uploaded files)
  - env.backup (Environment configuration)
  - docker-compose.prod.yml (Docker configuration)
EOF

# Calculate backup size
BACKUP_SIZE=$(du -sh ${BACKUP_DIR}/${BACKUP_NAME} | cut -f1)

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Backup completed successfully!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Backup Details:${NC}"
echo -e "  Location: ${BLUE}${BACKUP_DIR}/${BACKUP_NAME}${NC}"
echo -e "  Size:     ${BLUE}${BACKUP_SIZE}${NC}"
echo -e "  Files:"
echo -e "    - database.sql.gz"
echo -e "    - storage.tar.gz"
echo -e "    - env.backup"
echo -e "    - docker-compose.prod.yml"
echo -e "    - manifest.txt"
echo ""
echo -e "${YELLOW}To restore this backup:${NC}"
echo -e "  ${BLUE}./scripts/restore.sh ${BACKUP_NAME}${NC}"
echo ""

# Cleanup old backups (keep last 7)
echo -e "${YELLOW}Cleaning up old backups...${NC}"
cd ${BACKUP_DIR}
ls -t | grep studiobook_backup_ | tail -n +8 | xargs rm -rf 2>/dev/null || true
cd ..
echo -e "${GREEN}✓ Old backups cleaned up${NC}"
