---
model: haiku
name: git-commit
description: "Generate a conventional commit message from current-branch changes against main and create the commit. Use when asked to commit, write a commit message, or generate a commit."
---

# Commit Message Generator

Generate a conventional commit message from the current branch's changes and create the commit. Follow the steps below in order. Do not skip steps. Do not add steps.

## Step 1: Preflight Checks

1. Run `git rev-parse --is-inside-work-tree`. If this fails or prints anything other than `true`, stop and report: "Not inside a git repository."
2. Run `git rev-parse --verify main`. If this fails, stop and report: "No local `main` branch found. This skill requires one."

## Step 2: Gather the Diff

1. Run `git diff --cached`.
2. IF the output is non-empty: use this diff as the source for the commit message. Remember `STAGED = yes`.
3. ELSE run `git diff`.
   - IF this output is non-empty: use it as the source for the commit message. Remember `STAGED = no`.
   - ELSE (both diffs empty): stop and report: "No changes detected."

## Step 3: Determine the Issue Code Prefix

1. Run `git branch --show-current` to get the branch name.
2. Look for an issue code in the branch name: letters, a hyphen, then digits (e.g., `cad-1438` in `feature/cad-1438-remove-pages`, `PAY-3080` in `fix/PAY-3080-refund-bug`).
3. IF no issue code is found: no prefix. Skip to Step 4.
4. IF an issue code is found, run `git log main..HEAD --oneline` and count the output lines:
   - IF the count is 0 (this new commit will be the only commit on the branch): prefix the commit message with the issue code in UPPERCASE inside square brackets, e.g., `[CAD-1438] chore(sisense): Remove lingering pages`.
   - IF the count is 1 or more (the branch will have multiple commits): do NOT prefix. The issue code belongs on the PR title instead.

## Step 4: Write the Commit Message

Write a conventional commit message from the diff gathered in Step 2.

**Format:** `type(scope): Short description` (with the `[ISSUE-123] ` prefix from Step 3 if one applies).

**Rules:**
- Valid types, use exactly one of: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `style`, `perf`, `build`, `ci`
- Use sentence case and imperative tone ("Add feature", not "Added feature")
- Keep the subject line under 72 characters
- IF the diff touches more than one file: after the subject line, add a blank line, then a bullet list with one bullet per file summarizing its change
- IF the diff touches one file: the subject line alone is enough

## Step 5: Stage Changes (only if STAGED = no)

IF `STAGED = yes` from Step 2, skip to Step 6. Otherwise:

1. Run `git status --porcelain` to list modified/added/deleted paths.
2. Check every path against this sensitive list: `.env`, `credentials*`, `*.pem`, `*.key`, `id_rsa*`, any path containing `secret` or `token`. IF any path matches, stop and ask the user whether to stage it. Do not stage it without an explicit yes.
3. Stage each remaining path explicitly: `git add <path1> <path2> ...`. NEVER use `git add -A` or `git add .` (they can stage secrets, large binaries, or unrelated work).

## Step 6: Create the Commit

Run `git commit` with a HEREDOC for safe multi-line formatting:

```bash
git commit -m "$(cat <<'EOF'
type(scope): Short description

- Optional bullet list of per-file changes
EOF
)"
```

- IF the command succeeds: go to Step 7.
- IF a pre-commit hook fails: the commit did NOT happen. Fix the underlying issue, re-stage any files the fix changed, and run the same `git commit` command again to create a NEW commit. Do NOT use `--amend`. Do NOT use `--no-verify`.
- IF the command fails for any other reason: stop and report the exact error output to the user.

## Step 7: Confirm

1. Run `git log -1 --oneline` and print the new commit's short SHA and subject line.
2. Run `git status` and confirm the working tree state to the user.
