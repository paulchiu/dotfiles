#!/bin/zsh

set -e
source ~/.nvm/nvm.sh

# Extract the directory and branch from the current item
directory=${1%%:*}
branch=${1#*:}

# Change to the directory
cd "$DEV_HOME/$directory" || { echo "Failed to change to directory $directory"; exit 1; }

# Run the git commands
echo "In $directory"
nvm use
git fetch --all -p

# Wipe changes if not monorepo; need to preserve local Yarn version settings
if [[ "$directory" != "mr-yum" ]]; then
    git reset --hard HEAD
    git clean -df
fi

# Update branch
git checkout "$branch"
git pull origin "$branch"

# Check for lock files and install dependencies
if [[ -f "yarn.lock" ]]; then
    yarn install
elif [[ -f "package-lock.json" ]]; then
    npm install
else
    echo "$directory dependencies were not installed because no lock file found"
fi
