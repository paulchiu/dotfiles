#!/bin/sh

DEST=~/.fonts
TMP_DIR=/tmp/fonts/powerline
POWERLINE_FONTS_URI=https://github.com/powerline/fonts/archive/2015-12-04.zip
POWERLINE_FONTS_SUBDIR=fonts-2015-12-04

# Prepare shared folders
mkdir -p ${TMP_DIR}
mkdir -p ${DEST}

# Install powerline fonts
pushd ${TMP_DIR}
wget ${POWERLINE_FONTS_URI} -O p.zip
unzip p.zip
cd ${TMP_DIR}/${POWERLINE_FONTS_SUBDIR}
source install.sh
popd
