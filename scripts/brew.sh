#!/bin/sh

if [ ! -e /opt/homebrew/bin/brew ]
then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew install \
    dbeaver-community \
    dropbox \
    ag \
    bat \
    discord \
    editorconfig \
    easy-move-plus-resize \
    fd \
    firefox \
    gitui \
    google-drive \
    hiddenbar \
    iterm2 \
    karabiner-elements \
    keycastr \
    lnav \
    ngrok \
    nvm \
    maccy \
    macvim \
    messenger \
    p7zip \
    postman \
    ranger \
    raycast \
    rectangle \
    slack \
    stats \
    tmux \
    tree \
    visual-studio-code \
    wget \
    yarn \
    z \
    zappy \
    zoom
