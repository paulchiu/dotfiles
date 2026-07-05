---
model: haiku
name: yadm-sync
description: "Add, commit, and push dotfile changes with yadm. Use when asked to update/sync dotfiles, commit dotfile changes, track a new file with yadm, or save changes under ~/.claude or ~/.config."
---

# yadm Sync

Add, commit, and push dotfile changes using `yadm`.

## Hard rules (read before running anything)

- NEVER run `yadm status -u`, `yadm status -uall`, or any command that lists untracked files under `~`. The home directory contains hundreds of thousands of untracked files (caches, app bundles, Google Drive). Past runs produced 400MB+ of output and stalled the session.
- NEVER run `yadm add .` or `yadm add -A`. Always stage explicit file paths.
- If you do not know the exact file path(s) to stage, stop and ask the user. Do not scan the home directory to find candidates.
- Never use `--no-verify` or skip hooks unless the user explicitly asks.
- If a yadm command fails with an error not covered in [references/troubleshooting.md](references/troubleshooting.md), stop and report the exact error message to the user. Do not improvise recovery steps.

## Workflow

Work only from the file path(s) the user named, or that you edited earlier in this session.

1. Run `yadm status` (no flags; this is safe because it hides untracked files by default).
   - Expected: each tracked file you changed appears under "Changes not staged for commit".
   - New files, and files under gitignored directories (anything in `~/.claude/` or `~/.config/opencode/`), will NOT appear here. That is normal; continue.
   - If the command errors, or reports clean for a tracked file you know you just changed, open [references/troubleshooting.md](references/troubleshooting.md) and follow the "RTK rewrites yadm" section.
2. For each modified tracked file, run `yadm diff <path>`. For each new file, read the file directly. You need the change content to write the commit message.
3. Run `yadm log -5 --oneline` and note the style: Conventional Commits, one scope per commit (see scope conventions below).
4. Stage each file by its exact path:
   - Tracked and modified: `yadm add <path>`
   - New, or under a gitignored directory (`~/.claude/`, `~/.config/opencode/`): `yadm add -f <path>`
   - A "The following paths are ignored" hint on `-f` adds is expected for those directories. It is not an error.
   - If `yadm add` fails with "outside repository": follow the "RTK rewrites yadm" section in [references/troubleshooting.md](references/troubleshooting.md).
   - If `yadm add` fails mentioning `index.lock`: follow the "Lock contention" section in [references/troubleshooting.md](references/troubleshooting.md).
5. Decide the commit count:
   - If all staged files belong to one scope: one commit. Go to step 6.
   - If the files span multiple scopes (e.g. a `docs(claude)` tweak plus a new `feat(skills)` skill plus a `chore(shell)` zshrc edit): follow "Splitting into logical commits" below, then continue at step 7.
6. Commit with a Conventional-Commits-style subject that matches the recent log. Use a HEREDOC for multi-line bodies:

   ```bash
   yadm commit -m "$(cat <<'EOF'
   docs(claude): add dated-doc file naming rule

   Optional body paragraph explaining the why.
   EOF
   )"
   ```

   - If `yadm commit` fails mentioning `index.lock`: follow the "Lock contention" section in [references/troubleshooting.md](references/troubleshooting.md).
7. Decide whether to push:
   - If the user said only "commit": stop here. Report the commit subject and hash. Do NOT push.
   - If the user said "update", "sync", "push", or "add commit and push": run `yadm push`.
   - If `yadm push` fails: report the exact error and stop. Do not retry with force flags.
8. Run `yadm status` to confirm a clean tree, then report what was committed and pushed.

## Splitting into logical commits

The user's log keeps one scope per commit. When the changed files span multiple scopes:

1. Group the changed paths by scope (see scope conventions below). One scope per commit.
2. For each group in turn: run `yadm add <paths>` (with `-f` where step 4 requires it), then `yadm commit` with that group's scoped subject. Do not stage the next group until the previous commit has succeeded.
3. Push once at the end (`yadm push`, only if step 7 says to push). Do not push per-commit.
4. If a single file legitimately covers two scopes, pick the dominant scope and mention the other in the commit body. Do not split a single file across commits.

## Commit scope conventions

The user's yadm repo uses Conventional Commits with a scope tied to the path:

- `docs(claude):` for changes to `~/.claude/CLAUDE.md` or Claude-side docs.
- `feat(skills):` for new skills under `~/.config/opencode/skills/`.
- `chore(shell):` for `.zshrc` and other shell config tweaks.
- `feat(<skill-name>):` for changes inside a specific skill directory (e.g. `feat(ai-pril-manage-unblock-progress-reports)`).

Keep the subject short and descriptive. Add a body only when the subject alone cannot explain the why.

## Notes

- `.claude` is gitignored in yadm, so any file under `~/.claude/` needs `yadm add -f` on first stage.
- `~/.claude/skills` is a symlink to `~/.config/opencode/skills`. Edit skills under the opencode path and stage them at the opencode path.
