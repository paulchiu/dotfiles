#!/bin/sh

DEST=~/.fonts
DOWNLOAD_URI=https://github.com/tonsky/FiraCode/releases/download/1.204/FiraCode_1.204.zip
TMP_DIR=/tmp/fira-code
TTF_SUBDIR=ttf

# Get font
mkdir ${TMP_DIR}
pushd ${TMP_DIR}
wget ${DOWNLOAD_URI} -O f.zip
unzip f.zip
cd ${TTF_SUBDIR}

# Install font locally
mkdir ${DEST}
cp ${TMP_DIR}/${TTF_SUBDIR}/*.ttf ${DEST}
fc-cache -v
popd

