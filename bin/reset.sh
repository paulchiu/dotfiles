#!/bin/zsh

set -e

cd "$(dirname "$0")"

# Each step is guarded so a failure in one doesn't skip the rest: a declined
# sudo prompt or a single broken cask used to abort the whole reset.
./brew-upgrade.sh || echo "brew upgrade finished with failures"

# Repo sync moved to mrx: the list lives in ~/.config/mrx/2.0-stack.mrconfig
# and the per-repo work in mrx-sync-repo.sh. init-dev.sh is kept until this has
# a few clean runs behind it; swap the two lines back to revert.
# ./init-dev.sh
mrx -s 2.0-stack update -j 10 --exit-on-done || echo "repo sync finished with failures"

./zsh-refresh-caches.sh || echo "cache refresh finished with failures"
