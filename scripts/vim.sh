#!/bin/sh

DEST=~/

# Copy config files
cp vim/.vimrc ${DEST}
rsync -ah vim/.vim ${DEST}

echo "Optional scripts"
echo "   scripts/vundle.sh (installs vundle plugins)"
