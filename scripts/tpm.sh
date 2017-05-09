#!/bin/sh

DEST=~/

# Install tmux plugin manager manually if not exist
if [[ ! -e "${DEST}/.tmux/plugins/tpm/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm "${DEST}/.tmux/plugins/tpm"

    # Make plugins directory writable
    chmod -R 777 ~/.tmux/plugins
fi

# Trigger plugin installation
"${DEST}/.tmux/plugins/tpm/bin/install_plugins"

# Reload TMUX environment so TPM is sourced
tmux source ~/.tmux.conf