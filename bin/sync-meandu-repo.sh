#!/bin/zsh

# Per-repo sync, invoked by mrx via `update =` in the ~/.config/mrx/*.mrconfig
# repo sets.
# Replaces process_item.sh: mrx supplies the parallelism, the clone, and the
# output prefixing, so this only has to do the per-repo work.
#
# cwd is the repo. Everything else arrives as environment:
#   MR_REPONAME     section basename, for messages
#   MR_BRANCH       branch to track; defaults to whatever origin/HEAD points at
#   MR_RESET        "false" to keep local changes (the monorepo's Yarn settings)
#   MR_FORCE_INSTALL "true" to reinstall even when the lock file has not moved

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

# A non-interactive shell never runs mise's cd hook, so load the repo's pinned tools
# (.nvmrc and friends) here, after the pull may have changed them.
if command -v mise >/dev/null; then
  eval "$(mise env -s zsh)"
fi

# The stamp records which lock file the last completed install was built from,
# so an untouched lock can skip the install outright. Across a sweep this is
# the common case, and the install is the dominant cost either way: npm still
# takes minutes to decide it has nothing to do.
# It lives inside node_modules so losing the tree loses the claim with it.
stamp_file=node_modules/.sync-lock-hash

lock_hash() {
  shasum -a 256 "$1" | cut -d' ' -f1
}

dependencies_are_current() {
  [[ "${MR_FORCE_INSTALL:-false}" == "true" ]] && return 1
  [[ -d node_modules && -f $stamp_file ]] || return 1
  [[ "$(<$stamp_file)" == "$(lock_hash "$1")" ]]
}

lock=""
if [[ -f "pnpm-lock.yaml" ]]; then
  lock=pnpm-lock.yaml
elif [[ -f "yarn.lock" ]]; then
  lock=yarn.lock
elif [[ -f "package-lock.json" ]]; then
  lock=package-lock.json
fi

if [[ -z "$lock" ]]; then
  echo "$repo dependencies were not installed because no lock file found"
elif dependencies_are_current "$lock"; then
  echo "$repo dependencies already match $lock, skipping install"
else
  if [[ "$lock" == "pnpm-lock.yaml" ]]; then
    # Without a TTY pnpm aborts rather than ask to purge a tree another package manager built.
    pnpm install --config.confirm-modules-purge=false
  elif [[ "$lock" == "yarn.lock" ]]; then
    yarn install
  else
    npm install
  fi
  # Stamp only after the install returns clean, so an interrupted one reinstalls.
  # A package with nothing to install leaves no tree to stamp, and reinstalls.
  if [[ -d node_modules ]]; then
    lock_hash "$lock" > $stamp_file
  fi
fi

# Anti-fragile: refresh the codebase-memory index for this repo after the pull.
# Runs only if the helper exists; the `|| true` keeps `set -e` from aborting the
# sync if the refresh (or the codebase-memory tooling) is unavailable.
reindex_helper="${0:a:h}/cbm-reindex.sh"
if [[ -x "$reindex_helper" ]]; then
  "$reindex_helper" "$PWD" || true
fi
