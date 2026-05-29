#!/bin/zsh

# Script to run git-prune-local.sh across all git repositories in ~/dev
# Runs up to 10 parallel instances.
#
# Flags (e.g. --all, --help) are forwarded to git-prune-local.sh; a single
# non-flag argument overrides the search directory (default ~/dev).
#   git-prune-all.sh                  # smart prune across ~/dev
#   git-prune-all.sh --all            # force-clear all worktrees across ~/dev
#   git-prune-all.sh --all ~/work     # ...across ~/work instead

DEV_DIR="$HOME/dev"
PRUNE_ARGS=()
for arg in "$@"; do
    case "$arg" in
        -*) PRUNE_ARGS+=("$arg") ;;
        *)  DEV_DIR="$arg" ;;
    esac
done

PRUNE_SCRIPT="$HOME/bin/git-prune-local.sh"
MAX_JOBS=10

# Check if prune script exists
if [[ ! -x "$PRUNE_SCRIPT" ]]; then
  echo "Error: Prune script not found at $PRUNE_SCRIPT"
  exit 1
fi

# For an interactive --all run, the per-repo jobs run in parallel and can't each
# prompt safely. So confirm once here: pre-scan every repo, print the full list of
# worktrees that would be force-removed, prompt, then forward --yes to the children.
has_all=0
has_yes=0
for a in "${PRUNE_ARGS[@]}"; do
  case "$a" in
    -a|--all) has_all=1 ;;
    -y|--yes) has_yes=1 ;;
  esac
done

if (( has_all )) && (( ! has_yes )); then
  echo "Scanning worktrees under $DEV_DIR ..."
  targets=()
  while IFS= read -r gitdir; do
    repo="$(dirname "$gitdir")"
    main_wt="$(git -C "$repo" worktree list 2>/dev/null | head -1 | awk '{print $1}')"
    while IFS= read -r wt; do
      [[ -n "$wt" && "$wt" != "$main_wt" ]] && targets+=("$wt")
    done < <(git -C "$repo" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10)}')
  done < <(find "$DEV_DIR" -maxdepth 2 -type d -name ".git" 2>/dev/null)

  if (( ${#targets[@]} == 0 )); then
    echo "No non-main worktrees found under $DEV_DIR; nothing to do."
    exit 0
  fi

  echo "--all will FORCE-REMOVE these ${#targets[@]} worktree(s) across $DEV_DIR"
  echo "(uncommitted work in them will be discarded):"
  for wt in "${targets[@]}"; do
    echo "  - $wt"
  done
  if [[ ! -t 0 ]]; then
    echo "Refusing to proceed without confirmation (no TTY). Re-run with --yes." >&2
    exit 1
  fi
  printf "Proceed? [y/N] "
  read -r confirm
  [[ "$confirm" == [yY]* ]] || { echo "Aborted."; exit 0; }
  PRUNE_ARGS+=(--yes)
fi

# Function to prune a single repo
prune_repo() {
  local repo_dir="$1"
  local repo_name="$(basename "$repo_dir")"

  echo "Pruning: $repo_name"
  cd "$repo_dir" && "$PRUNE_SCRIPT" "${PRUNE_ARGS[@]}" 2>&1 | while read line; do
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
