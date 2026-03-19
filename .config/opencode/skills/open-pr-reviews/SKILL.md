---
name: open-pr-reviews
description: "Opens GitHub PR URLs in cmux tabs for review. Creates a workspace named 'Reviews YYYY-MM-DD' with one tab per PR, using git worktrees so multiple PRs from the same repo can be reviewed simultaneously. Use when asked to open PRs for review, set up PR review tabs, or start morning PR review routine."
---

# Open PR Reviews

Opens a set of GitHub pull request URLs as cmux workspace tabs, each in its own git worktree checked out to the correct branch. Supports multiple PRs from the same repo simultaneously.

## Workflow

1. **Ask** the user for a list of GitHub PR URLs (if not already provided). Accept plain URLs, markdown lists, or mixed text.
2. **Parse and deduplicate** using `scripts/parse-pr-urls.sh`:
   - Extract URLs matching `https://github.com/{org}/{repo}/pull/{number}`
   - Strip markdown link syntax, list markers, and whitespace
   - Deduplicate by exact PR URL (multiple PRs from the same repo are allowed)
3. **Find or create workspace** named `Reviews YYYY-MM-DD` (e.g. `Reviews 2025-03-11`):
   - Run `scripts/open-pr-reviews.sh` with the parsed, deduplicated PR arguments.
   - The script handles workspace creation/reuse, tab creation/reuse, worktree setup, and branch checkout.

## Running

Parse the PR URLs and pass them safely to the main script (the `#` in `org/repo#number` must be quoted to avoid being interpreted as a bash comment):

```bash
PARSED=() && while IFS= read -r line; do PARSED+=("$line"); done < <(scripts/parse-pr-urls.sh "text with PR urls here")
scripts/open-pr-reviews.sh "${PARSED[@]}"
```

The script will:
1. Find or create the `Reviews YYYY-MM-DD` workspace
2. For each PR:
   - Clone the repo to `~/dev/{repo}` if it doesn't exist (used as the main bare-like clone)
   - Create a git worktree at `~/dev/{repo}-pr-{number}` for the PR branch
   - Create a new tab (or reuse existing tab named `{repo} #{number}`)
   - `cd` into the worktree directory
   - Rename the tab to `{repo} #{number}`
   - Run `claude "use branch review skill"` to automatically start a review

## Cleanup

After finishing PR reviews, clean up worktrees to free disk space:

```bash
# Remove all PR worktrees (~/dev/*-pr-*)
scripts/cleanup-pr-worktrees.sh

# Force-remove even with uncommitted changes
scripts/cleanup-pr-worktrees.sh --force

# Remove worktrees matching a specific pattern
scripts/cleanup-pr-worktrees.sh ~/dev/myrepo-pr-*
```

The script also prunes stale git worktree entries automatically. Do **not** use `rm -rf` on worktree directories — always use this script or `git worktree remove`.

## Parsing Rules

- Extract URLs matching `https://github.com/{org}/{repo}/pull/{number}`
- Strip markdown link syntax, list markers (`- `, `* `, `1. `), and surrounding whitespace
- Deduplicate by exact PR (same org/repo#number), but allow multiple PRs from the same repo

## Requirements

- `cmux` CLI installed
- `gh` CLI installed and authenticated
- `git` installed
