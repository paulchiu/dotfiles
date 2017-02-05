#!/bin/bash

PLATFORM=$(uname)

# Install platform specific software
if [[ ${PLATFORM} == "Linux" && -e /usr/bin/apt ]]; then
    echo "Installing apt packages ..."
    source scripts/apt-gui.sh
    source scripts/fonts.sh
fi
