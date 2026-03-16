#!/usr/bin/env bash
set -euo pipefail

# Cleans up git worktrees created for PR reviews.
# Usage: cleanup-pr-worktrees.sh [--force] [pattern]
#   --force   Remove even if worktree has uncommitted changes
#   pattern   Glob pattern for worktree dirs (default: ~/dev/*-pr-*)

FORCE=""
PATTERN="$HOME/dev/*-pr-*"

while [[ $# -gt 0 ]]; do
	case "$1" in
	--force) FORCE="--force"; shift ;;
	*) PATTERN="$1"; shift ;;
	esac
done

REMOVED=0
FAILED=0

for dir in $PATTERN; do
	[[ -d "$dir" ]] || continue

	# Derive the main repo dir: ~/dev/repo-pr-123 -> ~/dev/repo
	repo_dir=$(echo "$dir" | sed -E 's/-pr-[0-9]+$//')

	if [[ ! -d "$repo_dir" ]]; then
		echo "SKIP: No main repo found at $repo_dir for worktree $dir"
		((FAILED++)) || true
		continue
	fi

	echo "Removing worktree: $dir"
	if git -C "$repo_dir" worktree remove "$dir" $FORCE 2>/dev/null; then
		((REMOVED++)) || true
	else
		echo "  FAILED: Could not remove $dir (use --force for uncommitted changes)"
		((FAILED++)) || true
	fi
done

# Prune stale worktree entries from all repos that had worktrees
for repo_dir in $HOME/dev/*/; do
	[[ -d "$repo_dir/.git" ]] || continue
	git -C "$repo_dir" worktree prune 2>/dev/null || true
done

echo ""
echo "Cleanup complete: $REMOVED removed, $FAILED skipped/failed."
