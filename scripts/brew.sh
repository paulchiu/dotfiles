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
    homebrew/versions/bash-completion2 \
    z \
    ag \
    Caskroom/cask/osxfuse \
    homebrew/fuse/sshfs \
    yarn \
    editorconfig \
    p7zip \
    ranger

brew tap homebrew/completions
