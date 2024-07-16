#!/bin/zsh

# Fetch the latest changes from the remote repository and prune deleted branches
git fetch --prune

# Loop through each local branch
for branch in $(git branch --format '%(refname:short)'); do
    # Check if the branch exists on the remote
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        # If the branch does not exist on the remote, delete the local branch
        git branch -D "$branch"
    fi
done
