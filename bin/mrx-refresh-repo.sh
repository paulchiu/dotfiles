#!/bin/zsh

# Per-repo refresh, invoked by mrx via `update =` in the repo sets that are
# checked out but not in daily rotation (2.0-misc, paulchiu, vendor).
#
# The counterpart to mrx-sync-repo.sh, minus everything destructive: no reset,
# no clean, no branch switch, no dependency install. A dormant repo's working
# tree is wherever its last session left it, and that state is worth more than
# a guaranteed-pristine checkout.
#
# cwd is the repo. Everything else arrives as environment:
#   MR_REPONAME  section basename, for messages

set -e

repo=${MR_REPONAME:-$(basename "$PWD")}

git fetch --all -p

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
if [[ -z "$upstream" ]]; then
  echo "$repo is on $(git rev-parse --abbrev-ref HEAD) with no upstream; fetched only"
elif ! git merge --ff-only "$upstream"; then
  # Diverged, or the merge would clobber uncommitted work. Either way the
  # fetch above already refreshed what `mrx status` reports.
  echo "$repo cannot fast-forward onto $upstream; working tree left as-is"
fi

reindex_helper="${0:a:h}/cbm-reindex.sh"
if [[ -x "$reindex_helper" ]]; then
  "$reindex_helper" "$PWD" || true
fi
