#!/bin/sh

BUNDLE_PATH=~/.vim/bundle
VUNDLE_PATH=~/.vim/bundle/Vundle.vim

if [ -d ${VUNDLE_PATH} ]
then
    pushd ${VUNDLE_PATH}
    git pull
    popd
else
    pushd ${BUNDLE_PATH}
    git clone https://github.com/VundleVim/Vundle.vim.git
    popd
fi
vim +PluginInstall +qall
