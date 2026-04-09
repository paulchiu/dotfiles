#!/bin/zsh

# Remove all non-main worktrees forcefully, then prune stale entries
for wt in $(git worktree list --porcelain | grep '^worktree ' | awk '{print $2}'); do
    # Skip the main worktree (the root repo)
    if git worktree list --porcelain | grep -A1 "^worktree $wt$" | grep -q '^bare$'; then
        continue
    fi
    main_wt="$(git worktree list | head -1 | awk '{print $1}')"
    if [[ "$wt" != "$main_wt" ]]; then
        echo "Removing worktree: $wt"
        git worktree remove --force "$wt" 2>/dev/null
    fi
done
git worktree prune

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
