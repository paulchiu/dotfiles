#!/bin/zsh

set -e

# Extract the directory and branch from the current item
directory=${1%%:*}
branch=${1#*:}

# Prefix all script output; source: https://unix.stackexchange.com/a/440439
exec > >(trap "" INT TERM ERR; sed "s/^/$directory | /")

# Match node version
source ~/.nvm/nvm.sh

# Check if directory exists, if not clone it
if [ ! -d "$directory" ]; then
  echo "$directory not found, cloning"
  git clone "git@github.com:mr-yum/$directory.git"
fi

# Change to the directory
cd "$DEV_HOME/$directory" || { echo "Failed to change to directory $directory"; exit 1; }

# Run the git commands
echo "In $directory"
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
nvm use
if [[ -f "yarn.lock" ]]; then
    yarn install
elif [[ -f "package-lock.json" ]]; then
    npm install
else
    echo "$directory dependencies were not installed because no lock file found"
fi
