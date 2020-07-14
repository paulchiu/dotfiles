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
  tig \
  zsh

# Install rupa/z manually
mkdir -p ~/bin
wget https://raw.githubusercontent.com/rupa/z/master/z.sh -O ~/bin/z.sh
chmod +x ~/bin/z.sh
