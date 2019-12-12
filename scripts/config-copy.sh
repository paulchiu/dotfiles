#!/bin/sh

DEST=~/
PLATFORM=$(uname)

# Copy config files
cp bash/.bash_profile ${DEST}
cp bash/.bash_prompt ${DEST}
cp bash/.aliases ${DEST}
cp zsh/.zshrc ${DEST}
cp git/.gitconfig ${DEST}
cp git/.gitignore_global ${DEST}
cp tmux/.tmux.conf ${DEST}

# Make platform specific changes
if [[ ${PLATFORM} == "Linux" && -e /usr/bin/apt ]]; then
    mv ${DEST}.bashrc ${DEST}.bashrc-original
    mv ${DEST}.bash_profile ${DEST}.bashrc
fi
