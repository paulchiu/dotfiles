#!/bin/bash
set -e
date

# Authenticate once, then refresh the sudo ticket in the background so casks
# that need root partway through the run don't re-prompt.
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" 2>/dev/null || exit
done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT

/opt/homebrew/bin/brew update
/opt/homebrew/bin/brew upgrade --no-ask
