#!/bin/sh

# Install software
echo "Installing brew ..."
source scripts/brew.sh

# Copy config files
echo "Copying config files ..."
source scripts/config-copy.sh

# Execute other config/install scripts
echo "Setting up vim, Vundle, and plugins ..."
source scripts/vim.sh
source scripts/vundle.sh

echo "Manual set up"
echo "    nvm (need to start new bash instance)";
