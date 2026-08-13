#!/bin/zsh

set -e

cd "$(dirname "$0")"
./brew-upgrade.sh

# Repo sync moved to mrx: the list lives in ~/.config/mrx/work.mrconfig and the
# per-repo work in mrx-sync-repo.sh. init-dev.sh is kept until this has a few
# clean runs behind it; swap the two lines back to revert.
# ./init-dev.sh
mrx -s work update -j 10 --exit-on-done || echo "repo sync finished with failures"

./zsh-refresh-caches.sh

