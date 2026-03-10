---
name: open-pr-reviews
description: "Opens GitHub PR URLs in cmux tabs for review. Creates a workspace named 'Reviews YYYY-MM-DD' with one tab per PR, checks out each PR branch. Use when asked to open PRs for review, set up PR review tabs, or start morning PR review routine."
---

# Open PR Reviews

Opens a set of GitHub pull request URLs as cmux workspace tabs, each checked out to the correct branch.

## Workflow

1. **Ask** the user for a list of GitHub PR URLs (if not already provided). Accept plain URLs, markdown lists, or mixed text.
2. **Parse and deduplicate** using `scripts/parse-pr-urls.sh`:
   - Extract URLs matching `https://github.com/{org}/{repo}/pull/{number}`
   - Strip markdown link syntax, list markers, and whitespace
   - Deduplicate by repo name — keep only the first PR URL encountered for each repo
3. **Find or create workspace** named `Reviews YYYY-MM-DD` (e.g. `Reviews 2025-03-11`):
   - Run `scripts/open-pr-reviews.sh` with the parsed, deduplicated PR arguments.
   - The script handles workspace creation/reuse, tab creation/reuse, directory setup, and branch checkout.

## Running

First, parse and deduplicate the PR URLs:

```bash
# Parse from a string or stdin
PARSED=$(scripts/parse-pr-urls.sh "text with PR urls here")
# Or: echo "text with PR urls" | scripts/parse-pr-urls.sh
```

Then run the main script with the parsed arguments:

```bash
scripts/open-pr-reviews.sh $PARSED
```

The script will:
1. Find or create the `Reviews YYYY-MM-DD` workspace
2. For each PR:
   - Clone the repo to `~/dev/{repo}` if it doesn't exist
   - Create a new tab (or reuse existing tab named `{repo} #{number}`)
   - `cd` into the repo directory
   - Checkout the PR branch with `gh pr checkout` (force checkout + hard reset to origin)
   - Rename the tab to `{repo} #{number}`

## Parsing Rules

- Extract URLs matching `https://github.com/{org}/{repo}/pull/{number}`
- Strip markdown link syntax, list markers (`- `, `* `, `1. `), and surrounding whitespace
- If duplicate repos appear, keep only the first URL for that repo

## Requirements

- `cmux` CLI installed
- `gh` CLI installed and authenticated
- `git` installed
