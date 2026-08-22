---
name: herdr
description: >
  Drive Herdr, the persistent terminal runtime for coding agents, via the herdr CLI:
  spawn sibling panes, start/prompt/wait on agents (claude, codex, opencode and 18
  more), read pane output, manage workspaces/tabs/sessions, attach over SSH.
  Triggers: "herdr", "start an agent in a pane", "ask the reviewer pane", "wait until
  that agent is blocked", "herdr --remote", "attach to the session".
---

# Herdr

Herdr is a background server that owns real PTYs. Terminals live inside it, so
agents survive detach, network loss, and the lid closing. It organises them as
workspace > tab > pane, recognises the coding agent inside each pane, and
classifies its lifecycle state.

Source of truth for CLI syntax is the installed binary, not this skill. This
skill was written against Herdr `0.8.2` (Homebrew, `/opt/homebrew/bin/herdr`).

## Step 1: Check availability

Run both checks before any other `herdr` command:

```bash
command -v herdr && test "${HERDR_ENV:-}" = 1
```

Interpret the result exactly:

- **Both pass**: this shell is inside a Herdr-managed pane. Proceed.
- **`herdr` found, `HERDR_ENV` unset**: Herdr is installed but you are outside
  it. You may answer setup, config, and install questions from
  `references/sessions.md`. Do **not** inspect or control the focused session:
  target resolution falls back to whatever pane the user is looking at.
- **`herdr` not found**: stop and report that the CLI is unavailable. Do not
  attempt fallbacks.

Two discovery footguns, both destructive:

- Never run bare `herdr` to explore. It launches or attaches the TUI and takes
  over your terminal.
- Never probe a nested mutating command by omitting its arguments.
  `herdr workspace create` is valid with defaults and **will execute**.

Discover syntax by running a command **group** with no subcommand:
`herdr agent`, `herdr pane`, `herdr workspace`, `herdr tab`, `herdr session`,
`herdr terminal`, `herdr worktree`, `herdr notification`, `herdr integration`.
`herdr --skill` prints the upstream agent skill shipped with the binary; read it
when this skill and the binary disagree.

## Step 2: Read exactly one reference for the task

- Task is starting, prompting, waiting on, or answering another **agent**
  (delegate a review, spawn a worker, "ask the codex pane", "wait until it is
  blocked"): read `references/delegation.md` and follow its numbered flow.
- Task is **pane or layout** mechanics, or running an **ordinary command**
  (split, move, resize, close, run a test watcher, tail a server, read output):
  read `references/panes.md`.
- Task is **server lifecycle, named sessions, remote attach, config, or
  install** (start the service, detach, `--remote`, keybindings, upgrade,
  troubleshooting): read `references/sessions.md`.

Do not read a reference the task does not need.

## Step 3: Apply these rules while executing

- **Parse IDs from JSON responses.** Public IDs are opaque handles (`w1`,
  `w1:t1`, `w1:p1`). Never predict, derive from sidebar order, or copy from
  examples. `workspace create` returns `.result.workspace`, `.result.tab`,
  `.result.root_pane`; `tab create` returns `.result.tab`, `.result.root_pane`;
  `pane split` returns `.result.pane`.
- **Always target explicitly.** Use `--current`, a pane ID, or a unique agent
  name. Omitting a target may hit the UI-focused pane, which can belong to the
  user or another client. Your own context is in `$HERDR_WORKSPACE_ID`,
  `$HERDR_TAB_ID`, `$HERDR_PANE_ID`.
- **Always pass `--timeout`.** `agent wait`, `agent prompt --wait`, and
  `pane wait-output` have no default timeout and will block indefinitely.
- **Always pass `--no-focus`** for background work unless the user asked to
  switch context. Stealing focus mid-task is disruptive.
- **Preserve cwd** on every split: `--cwd "$PWD"`. Splits do not inherit it.
- **Stay in the current tab.** Do not create a workspace, tab, or worktree
  unless the user explicitly asked for that topology.
- **Do not close what you did not create.** Workspaces, tabs, panes, sessions.
- **Never run `herdr server stop`** from an active session unless the user
  explicitly intends to kill every pane process. Never kill the main Herdr
  process. Use a named test session for experiments.
- CLI server errors are JSON on stderr with exit `1`. Syntax errors exit `2`.
  On an explicit error, stop and report the error and the exact command. Do not
  retry the same failing command.
