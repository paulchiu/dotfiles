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
4. Read the diff and check for mixed purposes. IF the changes serve two unrelated goals (example: a bug fix in `src/` plus an unrelated dependency bump in `package.json`), stop and ask the user whether to split into two commits. A single purpose with its supporting changes (a feature plus its tests and docs) is ONE commit; do not ask.

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

**Choosing the type (go down this list, first matching rule wins):**

1. Every changed file is a test file → `test`
2. Every changed file is documentation (`.md` files, `docs/`) → `docs`
3. Every changed file is CI or pipeline config (`.github/`, `.buildkite/`) → `ci`
4. The change corrects wrong behaviour (wrong output, crash, regression; changed conditionals or corrected values are the usual sign) → `fix`
5. The change adds a capability, option, endpoint, or command that did not exist → `feat`
6. Behaviour is unchanged and code is restructured, renamed, or moved → `refactor`
7. None of the above (dependency bumps, config, housekeeping) → `chore`

Use `style`, `perf`, or `build` only when the change is purely that and nothing above matched first.

**Choosing the scope:** run `git log --oneline -15` and reuse a scope name already in use when one fits the changed files. Otherwise use the directory or module that dominates the diff (e.g. `cart` for changes under `src/cart/`).

**Rules:**
- Use sentence case and imperative tone ("Add feature", not "Added feature")
- Keep the subject line under 72 characters
- The subject states the outcome, not the edit. IF your draft subject contains a file name, a function or variable name, or a vague verb ("update", "change", "modify") without saying what it accomplishes, rewrite it. Example: `fix(cart): Prevent duplicate order submission`, NOT `fix(cart): Update submit handler`.
- IF the diff touches more than one file: after the subject line, add a blank line, then a bullet list with one bullet per file summarizing its change. Each bullet states what the change does ("Add retry logic to the payment client"), never "Modified <file>" or "Updated <file>".
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
