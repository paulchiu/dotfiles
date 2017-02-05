#!/bin/sh

DEST=~/.fonts
TMP_DIR=/tmp/fonts/fira-code
FIRA_CODE_URI=https://github.com/tonsky/FiraCode/releases/download/1.204/FiraCode_1.204.zip
FIRA_CODE_SUBDIR=ttf

# Prepare shared folders
mkdir -p ${TMP_DIR}
mkdir -p ${DEST}

# Install fira code
pushd ${TMP_DIR}
wget ${FIRA_CODE_URI} -O f.zip
unzip f.zip
cd ${TMP_DIR}/${FIRA_CODE_SUBDIR}
cp ${TMP_DIR}/${FIRA_CODE_SUBDIR}/*.ttf ${DEST}
popd
fc-cache -v
