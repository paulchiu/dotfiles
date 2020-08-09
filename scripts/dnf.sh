#!/bin/sh

# Install dnf applications
sudo dnf update \
&& sudo dnf install -y \
  tmux \
  tree \
  wget \
  htop \
  bash-completion \
  the_silver_searcher \
  editorconfig \
  ranger \
  neofetch \
  bat \
  fd-find

# Install rupa/z manually
mkdir -p ~/bin
wget https://raw.githubusercontent.com/rupa/z/master/z.sh -O ~/bin/z.sh
chmod +x ~/bin/z.sh
