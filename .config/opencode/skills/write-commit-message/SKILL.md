---
name: write-commit-message
description: "Generates conventional commit messages from current branch changes against main. Use when asked to write a commit message, commit changes, or generate a commit."
---

# Commit Message Generator

Generate a conventional commit message from the current branch's staged or unstaged changes.

## Prerequisites

- Must be in a git repository with a local `main` branch
- Must have uncommitted or staged changes

## Workflow

### Step 1: Gather the Diff

1. Run `git diff --cached` to get staged changes.
2. If no staged changes, run `git diff` for unstaged changes.
3. If no changes at all, report "No changes detected" and stop.

### Step 2: Generate the Commit Message

Write a conventional commit message from the diff.

**Format:** `type(scope): Short description`

**Rules:**
- Valid types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `style`, `perf`, `build`, `ci`
- Use sentence case and imperative tone ("Add feature" not "Added feature")
- Keep the subject line under 72 characters
- For multiple files, add a blank line then a bullet list of per-file changes

### Step 3: Output

Output the raw commit message only. No explanation, no code blocks, no markdown formatting around it.
