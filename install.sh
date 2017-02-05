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

# Copy config files
echo "Copying config files ..."
source scripts/config-copy.sh

# Execute other config/install scripts
echo "Setting up vim, Vundle, and plugins ..."
source scripts/vim.sh
source scripts/vundle.sh

# Show what needs to be manually set up
echo "Manual set up"

if [[ ${PLATFORM} == "Darwin" ]]; then
    echo "    nvm (need to start new bash instance)";
    echo "    osxfuse (need to restart computer)";
elif [[ ${PLATFORM} == "Linux" && -e /usr/bin/apt ]]; then
    echo "    install-gui.sh (manually run if in windowed env)"
fi
