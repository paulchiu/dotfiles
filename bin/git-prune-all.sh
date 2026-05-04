#!/bin/zsh

# Script to run git-prune-local.sh across all git repositories in ~/dev
# Runs up to 10 parallel instances

DEV_DIR="${1:-$HOME/dev}"
PRUNE_SCRIPT="$HOME/bin/git-prune-local.sh"
MAX_JOBS=10

# Check if prune script exists
if [[ ! -x "$PRUNE_SCRIPT" ]]; then
  echo "Error: Prune script not found at $PRUNE_SCRIPT"
  exit 1
fi

# Function to prune a single repo
prune_repo() {
  local repo_dir="$1"
  local repo_name="$(basename "$repo_dir")"

  echo "Pruning: $repo_name"
  cd "$repo_dir" && bash "$PRUNE_SCRIPT" 2>&1 | while read line; do
    echo "[$repo_name] $line"
  done
}

echo "Finding git repositories in $DEV_DIR..."

# Find all git repos and process them with parallel limit
find "$DEV_DIR" -maxdepth 2 -type d -name ".git" 2>/dev/null | while read -r gitdir; do
  repo_dir="$(dirname "$gitdir")"

  # Run in background with job control
  prune_repo "$repo_dir" &

  # Limit parallel jobs
  while (($(jobs -r | wc -l) >= MAX_JOBS)); do
    sleep 0.1
  done
done

# Wait for all background jobs to finish
wait

echo "Done pruning all repositories"
