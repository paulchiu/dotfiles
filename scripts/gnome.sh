#!/bin/sh

DEST=~/.local/share
MIME_PACKAGES=${DEST}/mime/packages/
MIME_APPS=${DEST}/applications/

# Create VS Code Workspace associations
# Source: https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom-user.html.en

# Add MIME type
mkdir -p ${MIME_PACKAGES}
cp gnome/application-x-vscode.xml ${MIME_PACKAGES}
update-mime-database ~/.local/share/mime

# Add application association
mkdir -p ${MIME_APPS}
cp gnome/vscode.desktop ${MIME_APPS}
update-desktop-database ~/.local/share/applications