---
name: codex-app-cleanup
description: "Cleans stale Codex/ChatGPT desktop state: dead project picker entries, invalid env refs, obsolete worktree pairings. Use when Codex shows old projects/envs or stale worktrees still appear."
---

# Codex App Cleanup

Remove stale local desktop state that points at worktrees or project roots that no longer exist.

Use this for Codex macOS app cleanup, especially when the UI still shows dead local projects after the underlying worktrees were already deleted.

## When To Use

- The user says Codex still shows old projects in the project picker.
- The user says old envs, worktrees, or PR folders still appear in the desktop app.
- The user wants invalid local refs removed from Codex or ChatGPT desktop app state.
- The user mentions cleaned-up worktrees that are still cached in the app.

## Main Stores

### 1. Codex project picker state

The local project picker is backed by:

- `~/.codex/.codex-global-state.json`

Important keys:

- `electron-saved-workspace-roots`
- `electron-workspace-root-labels`
- `active-workspace-roots`
- `project-order`

If the stale entries appear in the project picker, this file is the primary source of truth.

### 2. ChatGPT desktop pairing cache

Old local environment refs may also live under:

- `~/Library/Application Support/com.openai.chat/app_pairing_extensions`

This store can contain stale pairing records, but removing those alone may not fix the project picker.

## Workflow

### 1. Inspect first

- Check whether Codex is currently running.
- Read `~/.codex/.codex-global-state.json`.
- List the current `electron-saved-workspace-roots`.
- If relevant, inspect `~/Library/Application Support/com.openai.chat/app_pairing_extensions`.

If the user named specific stale entries, search for those names directly first.

### 2. Verify which refs are actually invalid

Only remove entries that are genuinely dead.

For workspace roots in `.codex-global-state.json`:

- Treat a saved root as stale only if the directory no longer exists on disk.

For pairing extension records:

- Treat a record as stale only if it points at a missing local path or cleaned-up worktree.

Do not delete a path just because it looks like a PR worktree. If the directory still exists, keep it.

### 3. Quit Codex before editing project picker state

Before editing `~/.codex/.codex-global-state.json`:

- Quit the Codex app fully.
- Confirm the process is gone before writing the file.

This avoids racing the app's own state persistence.

### 4. Back up and prune safely

Before changing `.codex-global-state.json`:

- Create a timestamped backup next to the file.

Then:

- Remove missing paths from `electron-saved-workspace-roots`.
- Remove matching keys from `electron-workspace-root-labels`.
- Remove missing paths from `active-workspace-roots`.
- Remove missing paths from `project-order`.

Keep all unrelated keys unchanged.

For pairing extension cleanup:

- Delete only the specific stale pairing files or records that point at missing paths.

### 5. Validate and relaunch

After editing:

- Validate `.codex-global-state.json` as valid JSON.
- Verify every remaining saved workspace root still exists.
- Reopen Codex.

## Guardrails

- Never remove still-existing roots.
- Never wipe the whole global state file just to clear a few bad entries.
- Do not treat logs as the source of truth. Historic log lines can mention deleted paths long after cleanup.
- If the user only cares about the picker, prioritize `.codex-global-state.json` over pairing caches.
- Keep the cleanup narrow and reversible with a backup.

## Useful Checks

- Search for stale names inside `~/.codex/.codex-global-state.json`.
- Compare each saved workspace root to the filesystem with `test -d` or equivalent.
- If needed, search `~/Library/Application Support/com.openai.chat/app_pairing_extensions` for matching names.

## Output Style

When reporting back:

- State which store was the real source of the stale entries.
- Say how many invalid refs were removed.
- Mention the backup file path.
- Say whether Codex was relaunched or still needs relaunching.
