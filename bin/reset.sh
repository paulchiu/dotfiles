#!/bin/zsh

set -e

cd "$(dirname "$0")"
./brew-upgrade.sh
./init-dev.sh
