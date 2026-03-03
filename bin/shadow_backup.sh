#!/bin/bash
# Backup shadow.db to local backups folder
BACKUP_DIR="$HOME/Downloads/Resources/Shadow"
mkdir -p "$BACKUP_DIR"

# Create timestamped backup
cp "/Users/paul/Library/Application Support/com.taperlabs.shadow/shadow.db" "$BACKUP_DIR/shadow.db" 2>&1 | while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') - $line"; done
date +"%Y-%m-%d %H:%M:%S - Backup completed" >>"$BACKUP_DIR/backup.log"
