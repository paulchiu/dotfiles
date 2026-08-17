#!/bin/zsh

# Per-repo sync, invoked by mrx via `update =` in the ~/.config/mrx/*.mrconfig
# repo sets.
# Replaces process_item.sh: mrx supplies the parallelism, the clone, and the
# output prefixing, so this only has to do the per-repo work.
#
# cwd is the repo. Everything else arrives as environment:
#   MR_REPONAME  section basename, for messages
#   MR_BRANCH    branch to track; defaults to whatever origin/HEAD points at
#   MR_RESET     "false" to keep local changes (the monorepo's Yarn settings)

set -e

repo=${MR_REPONAME:-$(basename "$PWD")}

branch=${MR_BRANCH:-}
if [[ -z "$branch" ]]; then
  branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  branch=${branch:-main}
fi

git fetch --all -p

if [[ "${MR_RESET:-true}" != "false" ]]; then
  git reset --hard HEAD
  git clean -df
fi

git checkout "$branch"
git pull origin "$branch"

if [[ -f "yarn.lock" ]]; then
  yarn install
elif [[ -f "package-lock.json" ]]; then
  npm install
else
  echo "$repo dependencies were not installed because no lock file found"
fi

# Anti-fragile: refresh the codebase-memory index for this repo after the pull.
# Runs only if the helper exists; the `|| true` keeps `set -e` from aborting the
# sync if the refresh (or the codebase-memory tooling) is unavailable.
reindex_helper="${0:a:h}/cbm-reindex.sh"
if [[ -x "$reindex_helper" ]]; then
  "$reindex_helper" "$PWD" || true
fi
