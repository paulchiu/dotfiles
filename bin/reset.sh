#!/bin/zsh

set -e

cd "$(dirname "$0")"
./brew-upgrade.sh
./init-dev.sh
./zsh-refresh-caches.sh

# Sync shadow.db backup to Google Drive
echo "Syncing shadow.db backup to Google Drive..."
cp "$HOME/Downloads/Resource/Shadow/shadow.db" "/Users/paul/Library/CloudStorage/GoogleDrive-paul@meandu.com/My Drive/Resource/Shadow/shadow.db"
echo "Shadow backup synced successfully"
