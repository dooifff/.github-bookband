#!/bin/bash

# StudioBook Rollback Script
# Quick rollback to previous version

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COMPOSE_FILE="docker-compose.prod.yml"
BACKUP_DIR="./backups"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        StudioBook Rollback                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# List available backups
echo -e "${YELLOW}Available backups:${NC}"
echo ""

BACKUPS=($(ls -1t ${BACKUP_DIR} | grep studiobook_backup_ | head -10))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo -e "${RED}✗ No backups found!${NC}"
    exit 1
fi

for i in "${!BACKUPS[@]}"; do
    BACKUP_DATE=$(echo ${BACKUPS[$i]} | sed 's/studiobook_backup_//')
    BACKUP_SIZE=$(du -sh ${BACKUP_DIR}/${BACKUPS[$i]} | cut -f1)
    echo -e "  ${BLUE}$((i+1))${NC}. ${BACKUPS[$i]} (${BACKUP_SIZE})"
done

echo ""
read -p "Select backup number to restore (or 'q' to quit): " selection

if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
    echo -e "${YELLOW}Rollback cancelled${NC}"
    exit 0
fi

if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#BACKUPS[@]} ]; then
    echo -e "${RED}✗ Invalid selection!${NC}"
    exit 1
fi

SELECTED_BACKUP=${BACKUPS[$((selection-1))]}
echo ""
echo -e "${YELLOW}Selected: ${BLUE}${SELECTED_BACKUP}${NC}"
echo ""

# Confirm rollback
echo -e "${RED}⚠ WARNING: This will rollback to the selected backup!${NC}"
read -p "Are you sure you want to continue? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Rollback cancelled${NC}"
    exit 0
fi
echo ""

# Create current backup before rollback
echo -e "${YELLOW}Creating safety backup before rollback...${NC}"
if [ -f "scripts/backup.sh" ]; then
    ./scripts/backup.sh "pre-rollback" 2>/dev/null || true
    echo -e "${GREEN}✓ Safety backup created${NC}"
fi
echo ""

# Run restore script
echo -e "${YELLOW}Running restore...${NC}"
./scripts/restore.sh "${SELECTED_BACKUP}"

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Rollback completed!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Rolled back to:${NC}"
echo -e "  ${BLUE}${SELECTED_BACKUP}${NC}"
echo ""
echo -e "${YELLOW}To undo this rollback:${NC}"
echo -e "  ${BLUE}./scripts/rollback.sh${NC} (select the pre-rollback backup)"
