---
name: cleanup-sandbox
description: Clean up Paul's sandbox note repo by dating top-level documents, archiving files dated yesterday or earlier into archive/yyyy-mm/yyyy-mm-dd folders, normalising existing archive layout, and committing the result in logical git commits. Use when asked to "cleanup sandbox", archive old sandbox files, normalise dated docs, or commit the sandbox cleanup.
---

# Cleanup Sandbox

## Overview

Use this for the local sandbox workspace, usually `/Users/paul/dev/sandbox`.
The goal is to leave the root focused on today's docs, keep old dated files under
`archive/yyyy-mm/yyyy-mm-dd/`, and commit the result without staging local secrets.

## Core Rules

- Treat "older than yesterday" as inclusive by default: archive files dated `<= yesterday`.
- Use the current date and timezone from the environment context when available.
- Never read, stage, or commit `.openacp/`; it contains local OpenACP secrets.
- Treat workspace instruction files such as `AGENTS.md` and `CLAUDE.md` as config, not dated notes.
- Do not use `git add -A` or `git add .`.
- Use `git mv` for tracked files and plain `mv` for untracked files.
- Stop on destination collisions instead of overwriting.

## Workflow

1. Inspect the workspace:

   ```bash
   cd /Users/paul/dev/sandbox
   rg --files --max-depth 1 -g '*'
   git status --short
   ```

2. If top-level visible docs are not date-prefixed, use the
   `dated-doc-renamer` skill rules:

   - Preserve an existing `yyyy-mm-dd` prefix.
   - Otherwise use created-at date, not modified time.
   - Use a clear heading or first meaningful line for the title.
   - Skip hidden/config files such as `.gitignore`; do not touch `.openacp/`.

3. Move dated root files or directories with a prefix `<= yesterday` into:

   ```text
   archive/yyyy-mm/yyyy-mm-dd/yyyy-mm-dd Title.ext
   ```

4. Normalise existing archive entries. Any direct child of `archive/` named
   `yyyy-mm-dd Title...` moves under `archive/yyyy-mm/yyyy-mm-dd/`. Existing
   `archive/yyyy-mm-dd/` folders move under their matching `archive/yyyy-mm/`
   month folder. Existing `archive/yyyy-mm/` folders stay where they are.

5. Run the helper script when the task is the standard sandbox cleanup:

   ```bash
   zsh /Users/paul/.config/opencode/skills/cleanup-sandbox/scripts/cleanup_sandbox.zsh \
     --repo /Users/paul/dev/sandbox \
     --dry-run

   zsh /Users/paul/.config/opencode/skills/cleanup-sandbox/scripts/cleanup_sandbox.zsh \
     --repo /Users/paul/dev/sandbox \
     --apply
   ```

   The script handles date cutoff calculation, created-at dates, tracked vs
   untracked moves, and archive bucket normalisation. Read or patch the script
   only if the requested behaviour differs from the default.

6. Verify before committing:

   ```bash
   rg --files --max-depth 1 -g '*' | sort
   find archive -maxdepth 1 -type f -print | sort
   find archive -maxdepth 1 -mindepth 1 -type d -print | sort
   find archive -mindepth 2 -maxdepth 2 -type d -print | sort
   git status --short
   git check-ignore -v .openacp || true
   ```

   Expected shape:

   - No root files dated `<= yesterday`.
   - No direct files inside `archive/`.
   - First-level archive entries are `yyyy-mm` month folders.
   - Second-level archive entries are `yyyy-mm-dd` day folders.
   - `.openacp/` is ignored.

## Commit Pattern

Commit logically, not as one catch-all, unless there is only one kind of change.

For archive moves and date bucket normalisation:

```bash
git commit -m "$(cat <<'EOF'
chore(archive): Group dated notes by day

- Move dated archive entries into archive/yyyy-mm/yyyy-mm-dd folders
- Archive root files dated yesterday or earlier under matching month/day folders
- Preserve existing file contents while normalising note locations
EOF
)"
```

For current-day docs, safety notes, or `.gitignore` updates:

```bash
git commit -m "$(cat <<'EOF'
docs(openacp): Document local agent setup

- Add operating notes for OpenACP, Telegram setup, and Codex mode
- Preserve a local workspace warning note for future agents
- Ignore the local .openacp workspace because it contains secrets
EOF
)"
```

After committing, run:

```bash
git log -2 --oneline
git status --short
```
