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

## Never do

- **Never run `yadm status -u`, `yadm status -uall`, or any discovery that lists untracked files under `~`.** The home directory contains hundreds of thousands of untracked files across caches, app bundles, Google Drive, etc. Past runs have produced 400MB+ of output and stalled the session. If you don't know the file path to stage, ask the user rather than scanning.
- Never `yadm add .` or `yadm add -A` from `$HOME`. Always stage an explicit path.
