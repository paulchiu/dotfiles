#!/bin/sh

DEST=~/

# Install tmux plugin manager manually if not exist
if [[ ! -e "${DEST}/.tmux/plugins/tpm/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm "${DEST}/.tmux/plugins/tpm"
fi

# Trigger plugin installation
"${DEST}/.tmux/plugins/tpm/bin/install_plugins"
