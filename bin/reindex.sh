#!/usr/bin/env bash
#
# reindex.sh - trigger codebase-memory-mcp indexing without hand-writing JSON.
#
# Usage:
#   reindex.sh [path]            Full (re)index of path (default: current dir)
#   reindex.sh -i [path]         Incremental: only detect + re-index changes
#   reindex.sh -s [path]         Show index status, no indexing
#   reindex.sh -h                This help
#
# You pass a plain path; the script resolves it to an absolute path and derives
# the project name the tools expect (abs path, leading "/" dropped, "/" -> "-").

set -euo pipefail

BIN="${CODEBASE_MEMORY_BIN:-codebase-memory-mcp}"
mode="index"

while [[ "${1:-}" == -* ]]; do
  case "$1" in
    -i|--incremental) mode="incremental" ;;
    -s|--status)      mode="status" ;;
    -h|--help)
      grep '^#' "$0" | grep -v '^#!' | cut -c3-
      exit 0
      ;;
    *) echo "reindex: unknown option '$1'" >&2; exit 2 ;;
  esac
  shift
done

target="${1:-$PWD}"

if [[ ! -d "$target" ]]; then
  echo "reindex: not a directory: $target" >&2
  exit 1
fi

# Absolute, symlink-resolved path.
abs="$(cd "$target" && pwd -P)"

# Project name = abs path with leading slash removed and "/" -> "-".
project="${abs#/}"
project="${project//\//-}"

case "$mode" in
  index)
    echo "reindex: full index of $abs"
    exec "$BIN" cli index_repository "{\"repo_path\":\"$abs\"}"
    ;;
  incremental)
    echo "reindex: incremental changes for $project"
    exec "$BIN" cli detect_changes "{\"project\":\"$project\"}"
    ;;
  status)
    echo "reindex: status for $project"
    exec "$BIN" cli index_status "{\"project\":\"$project\"}"
    ;;
esac
