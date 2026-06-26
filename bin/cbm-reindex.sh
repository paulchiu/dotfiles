#!/bin/zsh
#
# cbm-reindex.sh — anti-fragile codebase-memory refresh.
#
# Refreshes the codebase-memory knowledge graph for a repo after a pull.
# Designed to be called from process_item.sh / init-dev.sh, but safe to run
# anywhere. Two guarantees:
#
#   1. No-op unless the tooling exists. If the `codebase-memory-mcp` CLI is not
#      installed, this script exits 0 immediately and does nothing.
#   2. Never fails its caller. Every failure path exits 0. A hung indexer is
#      bounded by a timeout. The worst case is a stale index, never a broken
#      dev sync.
#
# Usage:
#   cbm-reindex.sh [repo_path]      # defaults to $PWD
#
# Environment knobs (all optional):
#   CBM_REINDEX=0      Kill switch. Disable the refresh entirely.
#   CBM_INDEX_NEW=1    Also index repos that are NOT yet tracked (default: only
#                      refresh already-indexed repos, to avoid surprise-indexing
#                      huge or unrelated trees during a parallel sync).
#   CBM_MODE=fast      Index mode: fast | moderate | full (default: fast).
#   CBM_TIMEOUT=300    Per-repo wall-clock budget in seconds (default: 300).

emit() { print -r -- "[cbm-reindex] $*"; }

# 1. Kill switch.
[[ "${CBM_REINDEX:-1}" == "0" ]] && exit 0

# 2. Resolve the CLI. Absent tooling => silent no-op (requirement #1).
bin=$(command -v codebase-memory-mcp 2>/dev/null)
[[ -z "$bin" && -x "$HOME/.local/bin/codebase-memory-mcp" ]] && bin="$HOME/.local/bin/codebase-memory-mcp"
[[ -x "$bin" ]] || exit 0

# 3. Resolve the target repo.
repo="${1:-$PWD}"
repo="${repo:A}"                                   # absolute, symlinks resolved
[[ -d "$repo" ]] || { emit "skip: not a directory: $repo"; exit 0; }
git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { emit "skip: not a git repo: $repo"; exit 0; }

# 4. Derive the project name the way the indexer does: drop the leading slash,
#    swap remaining slashes for dashes. /Users/paul/dev/x -> Users-paul-dev-x
proj="${${repo#/}//\//-}"

# 5. Only refresh tracked repos unless explicitly told to index new ones.
idx=$("$bin" cli index_status "{\"project\":\"$proj\"}" 2>/dev/null)
if [[ "$idx" != *'"project"'* ]]; then
  if [[ "${CBM_INDEX_NEW:-0}" != "1" ]]; then
    emit "skip: not yet indexed ($proj); set CBM_INDEX_NEW=1 to index new repos"
    exit 0
  fi
  emit "indexing new repo: $proj"
fi

# 6. Refresh, bounded by a timeout so a stuck indexer can't stall the sync.
mode="${CBM_MODE:-fast}"
secs="${CBM_TIMEOUT:-300}"
payload="{\"repo_path\":\"$repo\",\"mode\":\"$mode\"}"

runner=()
to=$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null)
[[ -n "$to" ]] && runner=("$to" "$secs")

if "${runner[@]}" "$bin" cli index_repository "$payload" >/dev/null 2>&1; then
  emit "refreshed ($mode): $proj"
else
  emit "warn: refresh failed or timed out ($proj); index left as-is"
fi

exit 0
