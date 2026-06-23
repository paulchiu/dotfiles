#!/bin/zsh

# Options
all=0
assume_yes=0
for arg in "$@"; do
    case "$arg" in
        -a|--all) all=1 ;;
        -y|--yes) assume_yes=1 ;;
        -h|--help)
            echo "Usage: git-prune-local.sh [--all] [--yes]"
            echo "  (default)  Remove worktrees whose branch is gone from origin, or whose"
            echo "             detached HEAD has merged into the default branch; keep dirty"
            echo "             ones. Then delete local branches with no remote counterpart."
            echo "             For detached worktrees not yet on the default branch, fall"
            echo "             back to a gh check so squash/rebase-merged PRs are detected"
            echo "             (requires gh; skipped silently if unavailable)."
            echo "  -a, --all  Force-remove ALL non-main worktrees regardless of branch,"
            echo "             merge, or clean state (discards uncommitted work in them)."
            echo "             Prints the list and prompts for confirmation first."
            echo "  -y, --yes  Skip the --all confirmation prompt (for non-interactive use)."
            exit 0
            ;;
        *) echo "Unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

# Fetch the latest changes from the remote repository and prune deleted branches.
# In default mode, abort on failure: the removal logic trusts refs/remotes/origin/*,
# so acting on stale remote-tracking state could prune live worktrees. In --all mode
# the worktree removal is purely local, so a failed fetch only skips branch cleanup.
skip_branch_cleanup=0
if ! git fetch --prune; then
    if (( all )); then
        echo "git fetch --prune failed; continuing (--all is local), skipping branch cleanup" >&2
        skip_branch_cleanup=1
    else
        echo "git fetch --prune failed; aborting to avoid pruning from stale remote state" >&2
        exit 1
    fi
fi

# Determine the main worktree (first entry; never removed)
main_wt="$(git worktree list | head -1 | awk '{print $1}')"

# Determine the remote's default branch (e.g. origin/main), used to decide
# whether a detached worktree's commit has already landed
default_remote="$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null)"
default_remote="${default_remote#refs/remotes/}"
if [[ -z "$default_remote" ]]; then
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        default_remote="origin/main"
    elif git show-ref --verify --quiet refs/remotes/origin/master; then
        default_remote="origin/master"
    fi
fi

# Resolve the GitHub owner/repo once, used by the gh squash-merge fallback below.
# Empty if gh is unavailable, unauthenticated, or this isn't a GitHub remote, in
# which case the fallback is skipped and detached worktrees are kept conservatively.
repo_slug=""
if command -v gh >/dev/null 2>&1; then
    repo_slug="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"
fi

# In --all mode, list the worktrees that will be force-removed and confirm before
# touching anything. --yes skips the prompt; with no TTY we refuse rather than
# silently destroying work.
if (( all )) && (( ! assume_yes )); then
    targets=()
    while IFS= read -r wt; do
        [[ -n "$wt" && "$wt" != "$main_wt" ]] && targets+=("$wt")
    done < <(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10)}')

    if (( ${#targets[@]} == 0 )); then
        echo "No non-main worktrees to remove."
    else
        echo "--all will FORCE-REMOVE these ${#targets[@]} worktree(s) (uncommitted work discarded):"
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
    fi
fi

removed=()
kept=()

# Echoes a reason and returns non-zero when a worktree must be kept because it is
# either dirty or its status could not be read. A failed status read is treated
# as "keep" (not silently as "clean"), so a broken worktree is never removed.
worktree_keep_reason() {
    local out
    out="$(git -C "$1" status --porcelain 2>&1)"
    if (( $? != 0 )); then
        echo "status unreadable: ${out%%$'\n'*}"
        return 1
    fi
    if [[ -n "$out" ]]; then
        echo "has uncommitted changes"
        return 1
    fi
    return 0
}

# Returns 0 if a merged PR is associated with commit $1 on the GitHub remote. This
# catches squash/rebase merges, where the PR's head commit never becomes an ancestor
# of the default branch (so git merge-base --is-ancestor can't see it). Returns 1 on
# any uncertainty (no gh, no repo, network error, or no merged PR) so the caller keeps
# the worktree rather than removing on a false negative.
pr_commit_merged() {
    local head="$1" count
    [[ -n "$repo_slug" ]] || return 1
    count="$(gh api "repos/$repo_slug/commits/$head/pulls" \
        --jq '[.[] | select(.merged_at != null)] | length' 2>/dev/null)" || return 1
    [[ -n "$count" && "$count" -gt 0 ]]
}

# Walk every worktree and decide its fate. Reads via process substitution (not a
# pipe) so the kept/removed arrays survive into the summary below. The awk emits
# "-" for an empty branch so the tab-delimited fields don't collapse on read.
while IFS=$'\t' read -r wt branch detached head; do
    [[ "$branch" == "-" ]] && branch=""

    # Never touch the main worktree
    if [[ "$wt" == "$main_wt" ]]; then
        kept+=("$wt  (main worktree)")
        continue
    fi

    # --all: force-remove every non-main worktree regardless of state
    if (( all )); then
        echo "Removing worktree: $wt  [--all, forced]"
        if git worktree remove --force "$wt"; then
            removed+=("$wt")
        else
            kept+=("$wt  (--all, but removal failed)")
        fi
        continue
    fi

    # Detached-HEAD worktrees (e.g. PR checkouts): remove only once their commit
    # has landed. Prefer the local check (commit is an ancestor of the default
    # branch); if that says no, fall back to gh to catch squash/rebase merges where
    # the head commit never becomes an ancestor. Keep on any remaining uncertainty.
    if [[ "$detached" == "1" || -z "$branch" ]]; then
        merged_desc=""
        if [[ -n "$default_remote" ]] && git merge-base --is-ancestor "$head" "$default_remote" 2>/dev/null; then
            merged_desc="merged into $default_remote"
        elif pr_commit_merged "$head"; then
            merged_desc="PR squash/rebase-merged (via gh)"
        elif [[ -z "$default_remote" ]]; then
            kept+=("$wt  (detached; no default branch to compare)")
            continue
        else
            kept+=("$wt  (detached; not merged into $default_remote)")
            continue
        fi
        if ! reason="$(worktree_keep_reason "$wt")"; then
            kept+=("$wt  (detached & $merged_desc, but $reason)")
            continue
        fi
        echo "Removing worktree: $wt  [detached, $merged_desc]"
        if git worktree remove "$wt"; then
            removed+=("$wt")
        else
            kept+=("$wt  (detached & $merged_desc, but removal failed)")
        fi
        continue
    fi

    # Keep branch worktrees whose branch still exists on the remote
    if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        kept+=("$wt  [$branch] (branch still on remote)")
        continue
    fi

    # Branch is gone from the remote: remove the worktree, but never discard
    # uncommitted work
    if ! reason="$(worktree_keep_reason "$wt")"; then
        kept+=("$wt  [$branch] (branch gone, but $reason)")
        continue
    fi

    echo "Removing worktree: $wt  [$branch]"
    if git worktree remove "$wt"; then
        removed+=("$wt")
    else
        kept+=("$wt  [$branch] (branch gone, but removal failed)")
    fi
done < <(git worktree list --porcelain | awk '
    /^worktree / { wt = substr($0, 10); branch = ""; detached = 0; head = "" }
    /^HEAD /     { head = $2 }
    /^branch /   { branch = substr($0, 8); sub("refs/heads/", "", branch) }
    /^detached/  { detached = 1 }
    /^$/         { if (wt != "") print wt "\t" (branch == "" ? "-" : branch) "\t" detached "\t" head; wt = "" }
    END          { if (wt != "") print wt "\t" (branch == "" ? "-" : branch) "\t" detached "\t" head }
')

# Prune any stale administrative worktree entries
git worktree prune

# Sanity-check summary: report exactly which worktrees were left behind and why
echo
echo "Worktrees kept (${#kept[@]}):"
if (( ${#kept[@]} == 0 )); then
    echo "  (none)"
else
    for k in "${kept[@]}"; do
        echo "  - $k"
    done
fi
echo "Worktrees removed: ${#removed[@]}"

# Delete local branches with no remote counterpart. Skip any branch checked out
# in a worktree (its %(worktreepath) is non-empty): git refuses to delete those,
# and that includes the main worktree's branch, so this avoids spurious errors.
if (( skip_branch_cleanup )); then
    echo "Skipping local-branch cleanup (fetch failed)."
else
    while IFS=$'\t' read -r branch wtpath; do
        [[ -n "$wtpath" ]] && continue
        if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
            git branch -D "$branch"
        fi
    done < <(git branch --format '%(refname:short)%09%(worktreepath)')
fi
