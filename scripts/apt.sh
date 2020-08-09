#!/bin/sh

# Add repo for yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install apt-get applications
sudo apt-get update \
&& sudo apt-get install -y \
  tmux \
  tree \
  wget \
  htop \
  bash-completion \
  silversearcher-ag \
  yarn \
  editorconfig \
  ranger \
  zsh \
  fd-find \
  bat

# Install NVM manually
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

# Install rupa/z manually
mkdir -p ~/bin
wget https://raw.githubusercontent.com/rupa/z/master/z.sh -O ~/bin/z.sh
chmod +x ~/bin/z.sh
