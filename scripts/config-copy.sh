#!/bin/sh

DEST=~/

# Copy config files
cp bash/.bash_profile ${DEST}
cp bash/.bash_prompt ${DEST}
cp bash/.aliases ${DEST}
cp git/.gitconfig ${DEST}
cp tmux/.tmux.conf ${DEST}
