#!/bin/sh

# Install oh-my-zsh manually
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Install zsh nvm
git clone git@github.com:lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
