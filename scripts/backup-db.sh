#!/bin/bash
# AI WhatsApp Agent - Automated Database Backup Script
# This script is meant to be run via a daily cron job.

set -e

BACKUP_DIR="../db_backups"
DB_CONTAINER="agent_postgres"
DB_USER="n8n_user"
DB_NAME="whatsapp_agent_db"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/db_backup_${DATE}.sql.gz"

echo "🚀 Starting database backup for $DB_NAME..."

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Execute pg_dump inside the container and compress it
docker exec $DB_CONTAINER pg_dump -U $DB_USER $DB_NAME | gzip > "$BACKUP_FILE"

echo "✅ Backup created successfully: $BACKUP_FILE"

# Optional: Delete backups older than 30 days
echo "🧹 Cleaning up backups older than 30 days..."
find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +30 -exec rm {} \;

echo "🎉 Backup process completed."
