---
name: yadm-sync
description: "Add, commit, and push dotfile changes with yadm. Use when asked to update/sync dotfiles, commit dotfile changes, track a new file with yadm, or save changes under ~/.claude or ~/.config."
---

# yadm Sync

Add, commit, and push dotfile changes using `yadm`.

## Workflow

Assume the user has already told you (or you have already edited) the specific file(s) to stage. Work from that known path list. Do not scan the home directory for untracked files.

1. Run `yadm status` (no flags) to confirm modified tracked files. This is safe: it hides untracked by default.
2. Run `yadm diff <file>` for modified files, or read new files directly to understand the change.
3. Run `yadm log -5 --oneline` to match the recent commit style.
4. Stage the file(s) by exact path:
   - Tracked and modified: `yadm add <path>`
   - New, or `.gitignore`-blocked (e.g. anything under `.claude/`, `.config/opencode/`): `yadm add -f <path>`
5. Commit with a Conventional-Commits-style subject that matches the recent log. Use a HEREDOC for multi-line bodies:

   ```bash
   yadm commit -m "$(cat <<'EOF'
   docs(claude): add dated-doc file naming rule

   Optional body paragraph explaining the why.
   EOF
   )"
   ```

6. Run `yadm push`.
7. Run `yadm status` to confirm a clean tree.

## Splitting into logical commits

If the staged set spans multiple scopes (e.g. a `docs(claude)` tweak plus a new `feat(skills)` skill plus a `chore(shell)` zshrc edit), commit each scope separately rather than one mixed commit. The user's recent log keeps one scope per commit.

1. Group the changed paths by scope (see scope conventions below). One scope per commit.
2. For each group: `yadm add <paths>`, then `yadm commit` with the scoped subject. Do not stage the next group until the previous commit has succeeded.
3. Push once at the end (`yadm push`), not per-commit.
4. If a single file legitimately covers two scopes, pick the dominant one and mention the other in the body. Don't fragment a single file across commits.

## Commit scope conventions

The user's yadm repo uses Conventional Commits with a scope tied to the path:

- `docs(claude):` for changes to `~/.claude/CLAUDE.md` or Claude-side docs.
- `feat(skills):` for new skills under `~/.config/opencode/skills/`.
- `chore(shell):` for `.zshrc` and other shell config tweaks.
- `feat(<skill-name>):` for changes inside a specific skill directory (e.g. `feat(ai-pril-manage-unblock-progress-reports)`).

Keep the subject short and descriptive. Put the "why" in the body only when the subject alone is insufficient.

## Notes

- `.claude` is gitignored in yadm, so any file under `~/.claude/` needs `yadm add -f` on first stage. The "paths are ignored" hint is expected, not an error.
- `~/.claude/skills` is a symlink to `~/.config/opencode/skills`, so edit skills under the opencode path and stage them there.
- Do not use `--no-verify` or skip hooks unless the user explicitly asks.
- If the user said "commit" only, stop after commit. If they said "update", "sync", or "add commit and push", complete the full cycle through push.

## RTK gotcha

The Claude Code hook routes `yadm` through `rtk` (Rust Token Killer). RTK's `yadm status` summary can return a stale `clean — nothing to commit` line even when files in `~/.config/opencode/` or `~/.claude/` are modified. If `yadm status` claims clean but you know you just edited a tracked file, run `rtk proxy yadm status --short` to bypass the cache. If RTK still gets in the way, fall back to operating the underlying repo directly:

```
git --git-dir=$(yadm introspect repo) --work-tree="$HOME" status --short
```

Use the same pattern (`rtk proxy yadm <cmd>` or the explicit `git --git-dir=...`) for `add`, `diff`, `commit`, and `push` if RTK keeps short-circuiting. Always run a final `rtk proxy yadm status --short` to confirm the tree is actually clean.

## Lock contention (`.git/index.lock`)

If `yadm add` or `yadm commit` fails with `Unable to create '.../index.lock': File exists` (or EPERM in a delegated process like codex), another `yadm`/`git` process is likely mid-write against the bare repo. The repo lives at `$(yadm introspect repo)`, and the lock is `$(yadm introspect repo)/index.lock`.

1. Check whether anything actually holds the lock:

   ```bash
   REPO=$(yadm introspect repo)
   ls -l "$REPO/index.lock" 2>/dev/null
   lsof "$REPO/index.lock" 2>/dev/null
   pgrep -fl 'yadm|git.*'"$REPO" || true
   ```

2. If a live process owns it: wait and retry once (`sleep 2`, then re-run the failed command). If it still fails, sleep 5 and retry once more. Do not loop indefinitely.
3. If no process owns it (stale lock from a crashed/killed run, common after a codex EPERM): remove just the lock file and retry: `rm "$REPO/index.lock"`. Do not `rm -rf` anything else under `$REPO`.
4. If the contention is with the main Claude thread (codex was delegated and hit EPERM), stop the codex-side yadm work and have the main thread complete the sync. Two writers against the same yadm repo is the root cause; fixing the lock without fixing the contention will recur.

## Never do

- **Never run `yadm status -u`, `yadm status -uall`, or any discovery that lists untracked files under `~`.** The home directory contains hundreds of thousands of untracked files across caches, app bundles, Google Drive, etc. Past runs have produced 400MB+ of output and stalled the session. If you don't know the file path to stage, ask the user rather than scanning.
- Never `yadm add .` or `yadm add -A` from `$HOME`. Always stage an explicit path.
