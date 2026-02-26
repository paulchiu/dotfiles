#!/bin/bash
# Backup shadow.db to local backups folder
BACKUP_DIR="$HOME/Downloads/Resource/Shadow"
mkdir -p "$BACKUP_DIR"

# Create timestamped backup
cp "/Users/paul/Library/Application Support/com.taperlabs.shadow/shadow.db" "$BACKUP_DIR/shadow.db"
date +"%Y-%m-%d %H:%M:%S - Backup completed" >>"$BACKUP_DIR/backup.log"
