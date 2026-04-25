---
name: git-commit
description: "Generate a conventional commit message from current-branch changes against main and create the commit. Use when asked to commit, write a commit message, or generate a commit."
---

# Commit Message Generator

Generate a conventional commit message from the current branch's changes and create the commit.

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

### Issue Code Prefix

When the current branch name contains an issue code (e.g., `feature/cad-1438-...`, `fix/PAY-3080-...`), extract it.

- **Single commit on the branch**: Prefix the commit message with the issue code in brackets, e.g., `[CAD-1438] chore(sisense): Remove lingering pages`
- **Multiple commits on the branch**: Do NOT prefix individual commits. The issue code belongs on the PR title instead.

To determine commit count, run `git log main..HEAD --oneline` and count the results.

### Step 3: Stage Changes (if needed)

If `git diff --cached` was empty in Step 1, stage the changed files before committing:

1. Run `git status --porcelain` to list modified/added/deleted paths.
2. Stage each path explicitly with `git add <path1> <path2> ...`. Never use `git add -A` or `git add .` (avoids accidentally staging secrets, large binaries, or unrelated work).
3. If any path looks sensitive (`.env`, `credentials*`, `*.pem`, `*.key`, `id_rsa*`, anything containing `secret`/`token`), stop and ask the user before staging it.

### Step 4: Create the Commit

Run `git commit` with a HEREDOC for safe multi-line formatting:

```bash
git commit -m "$(cat <<'EOF'
type(scope): Short description

- Optional bullet list of per-file changes
EOF
)"
```

If a pre-commit hook fails, the commit did NOT happen. Fix the underlying issue and create a NEW commit (do not amend, do not pass `--no-verify`).

### Step 5: Confirm

Print the new commit's short SHA and subject line, then run `git status` to confirm the working tree state.
