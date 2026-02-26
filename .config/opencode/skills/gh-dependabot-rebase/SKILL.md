---
name: gh-dependabot-rebase
description: Bulk comment @dependabot rebase on open Dependabot PRs in GitHub repositories. Use when the user wants to rebase multiple Dependabot PRs at once, or when they mention rebasing Dependabot PRs in bulk. Triggers include requests like "rebase all dependabot PRs", "comment rebase on dependabot PRs", "bulk rebase dependabot PRs in repo OWNER/REPO".
---

# GH Dependabot Rebase

Bulk comment `@dependabot rebase` on all open Dependabot PRs in a GitHub repository.

## Usage

Run the script with the repository in `owner/repo` format:

```bash
scripts/dependabot-rebase.sh paulchiu/poe-editor
```

This will:
1. List all open PRs authored by `dependabot`
2. Comment `@dependabot rebase` on each PR
3. Print a summary of actions taken

## Requirements

- `gh` CLI installed and authenticated
- Access to the target repository
- Permissions to comment on PRs

## Script

**scripts/dependabot-rebase.sh** - Bash script that automates the commenting process.
