---
name: nex
description: "nex CLI: split/create/close/move/rename/capture panes, workspaces, groups, delegate to live panes with cxd/ccd."
model: haiku
---

# Nex

Use the local `nex` CLI to manage Nex panes and live agent delegation.

Source of truth for CLI syntax: `/Applications/Nex.app/Contents/Helpers/nex`.
This skill was consolidated against Nex `0.23.0`.

## Step 1: Check Nex availability

Run this before any other `nex` command:

```bash
nex pane id
```

Interpret the result exactly:

- Exit `0` and a UUID printed: the current shell is inside a Nex pane. Proceed.
- Exit `1` and empty output: the current shell is outside Nex. The app may
  still be running; `pane split`, `pane create`, and `pane send` can return
  exit `0` without doing anything. When delegating, follow the outside-Nex
  branch in `references/delegation.md` step 2. For other tasks, confirm every
  state change with `nex pane list --json`.
- "command not found" or any other error: stop and report that the `nex` CLI
  is unavailable. Do not attempt fallbacks.

Some Nex commands silently no-op when the app, socket, or pane context is
unavailable. Whenever state matters, verify with `nex pane list --json` instead
of trusting a zero exit code.

## Step 2: Read exactly one reference for the task

- Task mentions delegating work, `cxd`, `ccd`, "Codex pane", or "Claude pane":
  read `references/delegation.md` and follow its numbered flow.
- Task is pane, workspace, group, layout, file-open, diff, or web-view
  management (split, create, close, move, rename, capture, send, broadcast to a
  group, open a file or URL): read `references/terminal.md`. It also covers the
  SQLite-join recipe for broadcasting to every pane in a group (no CLI filter
  exists for this) and the web-view dark-theme gotcha (`prefers-color-scheme`
  is not honoured reliably, so generate HTML with an explicit dark theme).
- Task is driving an interactive terminal app in a pane (a TUI, an editor, a
  manual test sweep) or photographing what a pane drew: read
  `references/driving-tuis.md` **before sending a single key**. `pane send
--bare` silently rewrites control bytes as spaces, which corrupts a run
  rather than failing it, and `screencapture` writes no file on a stale window
  id, which quietly duplicates one frame across every screenshot. The reference
  carries the pty-shim workaround for both.
- Task is showing Codex progress, status indicators, or Nex notifications for
  Codex work: read `references/codex-status.md`.

Do not read a reference the task does not need.

## Step 3: Apply these rules while executing

- Prefer live pane workflows for delegation: create a pane, launch the agent
  alias in that pane, then send the prompt to the running agent.
- Alias selection is fixed: if the user says `cxd` or "Codex pane", use `cxd`.
  If the user says `ccd` or "Claude pane", use `ccd`. If the user does not
  specify, use `cxd`.
- Treat `ccd` and `cxd` as user-managed launch aliases with privileges already
  configured. Do not add model or permission flags unless the user asks.
- For one or two worker panes, coordinate directly in the live panes. For three
  or more panes, use clear pane labels, disjoint ownership, `pane list`, and
  `pane capture`. Do not use result-file fan-out unless the user asks for it.
- When multiple agents may touch the same repo, give each pane explicit file or
  responsibility ownership and tell it not to revert user or other agent
  changes.
- After any `pane send` that launches an agent or delivers a prompt, verify
  with `nex pane capture --target <id> --lines 40`. If the capture does not
  show the sent text or the expected agent UI, retry the send once at most,
  then use the focused-pane fallback in `references/delegation.md`.
- `pane name <name>` renames the **current** pane and takes no `--target`.
  Running it to label a pane you just created renames your own instead.
- Never send control bytes with `pane send --bare`. It rewrites most of them as
  spaces without erroring, so the keystroke lands as something else. Use
  `pane send-key` for the keys it supports (`enter, return, tab, escape, esc,
space, backspace, up, down, left, right, ctrl-c`) and the pty shim in
  `references/driving-tuis.md` for anything else.
- If a command fails with an explicit error, stop and report the error and the
  exact command. Do not keep retrying the same failing command.
