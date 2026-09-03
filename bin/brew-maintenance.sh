#!/bin/bash
# Daily launchd entry point: brew upgrade, then regenerate the zsh caches that
# depend on the upgraded binaries. Deliberately not `&&` chained, so a brew
# failure (a cask needing sudo has no tty here) still leaves the caches fresh.
date
status=0

/Users/paul/bin/brew-upgrade.sh || {
  status=$?
  echo "brew-upgrade.sh failed with $status" >&2
}

/Users/paul/bin/zsh-refresh-caches.sh || {
  status=$?
  echo "zsh-refresh-caches.sh failed with $status" >&2
}

exit "$status"
