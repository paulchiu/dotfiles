#!/bin/sh

# Install oh-my-zsh manually
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Install starship
curl -fsSL https://starship.rs/install.sh | bash
# Install zsh nvm
git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
# Install nvm auto
git clone https://github.com/dijitalmunky/nvm-auto.git "$ZSH/plugins/nvm-auto"
