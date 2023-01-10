#!/bin/bash

PLATFORM=$(uname)

# Install platform specific software
if [[ ${PLATFORM} == "Darwin" ]]; then
    echo "Installing brew and packages ..."
    source scripts/brew.sh
    source scripts/ohmyzsh.sh
elif [[ ${PLATFORM} == "Linux" && -e /usr/bin/apt ]]; then
    echo "Installing apt packages ..."
    source scripts/apt.sh
elif [[ ${PLATFORM} == "Linux" && -e /usr/bin/dnf ]]; then
    echo "Installing dnf packages ..."
    source scripts/dnf.sh
fi

# Install common GUI software
if [[ -e /usr/bin/startx ]]; then
    echo "Installing fonts ..."
    source install-fonts.sh
    echo "Setting up Gnome ..."
    source scripts/gnome.sh
fi

# Install platform specific GUI software
if [[ -e /usr/bin/startx && -e /usr/bin/apt ]]; then
    echo "Installing GUI apt packages ..."
    source scripts/apt-gui.sh
elif [[ -e /usr/bin/startx && -e /usr/bin/dnf ]]; then
    echo "Installing GUI dnf packages ..."
    source scripts/dnf-gui.sh
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
    echo "    osxfuse (need to restart computer)";
    echo "    iterm2 preferred theme is Dracula; 💾 @ https://iterm2colorschemes.com/";
    echo "    Syntax Highlight and QL Markdown need to be launched manually then configured as Quicklook extensions";
elif [[ ${PLATFORM} == "Linux" && -e /usr/bin/dnf ]]; then
    echo "    need to add .bash_profile to .bash_rc; also need to install config and do same for root";
fi
