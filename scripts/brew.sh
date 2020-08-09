#!/bin/sh

if [ ! -e /usr/local/bin/brew ]
then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew install \
    tmux \
    tree \
    nvm \
    wget \
    lnav \
    z \
    ag \
    yarn \
    editorconfig \
    p7zip \
    ranger \
    fd \
    bat
