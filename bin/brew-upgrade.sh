#!/bin/bash
set -e
date

# Authenticate once, then refresh the sudo ticket in the background so casks
# that need root partway through the run don't re-prompt. Touch ID being
# declined or timing out is not fatal: brew still prompts on its own if it
# actually needs root, and aborting here would take the whole reset.sh run down.
if sudo -v; then
  while true; do
    sudo -n true || exit
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
  done 2>/dev/null &
  SUDO_KEEPALIVE=$!
  trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT
else
  echo "brew-upgrade: sudo auth skipped, casks needing root will prompt individually." >&2
fi

/opt/homebrew/bin/brew update
# --no-quit keeps running cask apps alive, including the terminal hosting this script.
/opt/homebrew/bin/brew upgrade --no-ask --no-quit
