#!/bin/sh

DEST=~/

# Copy config files
cp vim/.vimrc ${DEST}
rsync -ah vim/.vim ${DEST}
