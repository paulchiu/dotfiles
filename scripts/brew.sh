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
    lazygit \
    lazydocker \
    lnav \
    ngrok \
    nvm \
    maccy \
    messenger \
    p7zip \
    postman \
    ranger \
    raycast \
    rectangle \
    slack \
    starship \
    stats \
    tmux \
    tree \
    visual-studio-code \
    wget \
    yarn \
    z \
    zappy \
    zoom

brew install --cask \
    macvim