#!/bin/bash

PLATFORM=$(uname)

# Install platform specific software
if [[ ${PLATFORM} == "Darwin" ]]; then
    echo "Installing brew and packages ..."
    source scripts/brew.sh
elif [[ ${PLATFORM} == "Linux" && -e /usr/bin/apt ]]; then
    echo "Installing apt packages ..."
    source scripts/apt.sh
fi

# Install common GUI software
if [[ -e /usr/bin/startx ]]; then
    echo "Installing fonts ..."
    source install-fonts.sh
fi

# Install platform specific GUI software
if [[ -e /usr/bin/startx && -e /usr/bin/apt ]]; then
    echo "Installing GUI apt packages ..."
    source scripts/apt-gui.sh
fi

# Copy config files
echo "Copying config files ..."
source scripts/config-copy.sh

# Execute other config/install scripts
echo "Setting up vim, Vundle, and plugins ..."
source scripts/vim.sh
source scripts/vundle.sh

echo "Setting up tmux and plugins ..."
source scripts/tmux.sh
source scripts/tpm.sh

# Show what needs to be manually set up
echo "Manual set up"

if [[ ${PLATFORM} == "Darwin" ]]; then
    echo "    nvm (need to start new bash instance)";
    echo "    osxfuse (need to restart computer)";
fi
