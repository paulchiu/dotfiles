#!/bin/sh

if [ ! -e /usr/local/bin/brew ]
then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew install tmux  \
&& brew install tree \
&& brew install nvm \
&& brew install wget \
&& brew install homebrew/versions/bash-completion2 \
&& brew tap homebrew/completions \
&& brew install z
