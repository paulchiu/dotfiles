#!/bin/sh

# Install apt-get applications
sudo apt-get install tmux  \
&& sudo apt-get install tree \
&& sudo apt-get install wget \
&& sudo apt-get install lnav \
&& sudo apt-get install htop \
&& sudo apt-get install bash-completion \
&& sudo apt-get install silversearcher-ag

# Install rupa/z manually
mkdir -p ~/bin
wget https://raw.githubusercontent.com/rupa/z/master/z.sh -O ~/bin/z.sh
chmod +x ~/bin/z.sh
