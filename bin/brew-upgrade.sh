#!/bin/bash
set -e
date

# Pre-authenticating only pays off where sudo caches a ticket. Kandji sets
# `Defaults timestamp_timeout=0` on this machine, so it doesn't: `sudo -v` would
# cost a prompt and buy nothing. Flip to 1 if that policy ever changes.
SUDO_CACHES=0

if [ "$SUDO_CACHES" = 1 ] && sudo -v; then
  while true; do
    sudo -n true 2>/dev/null || exit
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
  done &
  SUDO_KEEPALIVE=$!
  # `|| :` matters: in bash a failing EXIT trap becomes the script's exit status,
  # so a dead keepalive would make `brew-upgrade.sh && ...` short-circuit.
  trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || :' EXIT
fi

/opt/homebrew/bin/brew update

# Leave `auto_updates true` casks to their own updaters, per
# bootstrap/brew-self-managed.txt. Brew's swap of a self-updating cask runs
# privileged launchctl/rm steps that re-prompt for sudo on every call here.
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

# --no-quit keeps running cask apps alive, including the terminal hosting this script.
/opt/homebrew/bin/brew upgrade --no-ask --no-quit
