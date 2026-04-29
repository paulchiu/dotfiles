---
name: nex
description: >
  Manage Nex terminal workflows with the nex CLI. Use when asked to split,
  create, close, move, rename, capture, or send to panes; manage workspaces,
  groups, layouts, file opening, or diffs; show Codex progress/status in Nex;
  or delegate work to live Nex panes using cxd/ccd agent aliases. Trigger
  phrases include "delegate to Nex pane", "Codex pane", "Claude pane", "ccd",
  "cxd", "split pane", "send to pane", "capture pane", "open in Nex",
  "Nex indicator", or "Nex status".
---

# Nex

Use the local `nex` CLI to manage Nex panes and live agent delegation.

Source of truth for CLI syntax: `/Applications/Nex.app/Contents/Helpers/nex`.
This skill was consolidated against Nex `0.22.0`.

## Core Rules

- Prefer live pane workflows for Nex delegation. Create a pane, launch the agent
  alias in that pane, then send the prompt to the running agent.
- For generic delegation, prefer `cxd`.
- If the user says `cxd` or "Codex pane", use `cxd`.
- If the user says `ccd` or "Claude pane", use `ccd`.
- Treat `ccd` and `cxd` as user-managed launch aliases with privileges already
  configured. Do not add permission flags unless the user asks.
- For one or two worker panes, coordinate directly in the live panes. For larger
  pane counts, scale with clear pane labels, disjoint ownership, `pane list`, and
  `pane capture`; do not default to result-file fan-out unless the user asks.
- When multiple agents may touch the same repo, give each pane explicit file or
  responsibility ownership and tell it not to revert user or other agent changes.
- Before relying on Nex state, check availability with `nex pane id` or
  `nex pane list`.

## Progressive Disclosure

Load only the reference needed for the task:

- For pane, workspace, group, layout, file-open, and diff command syntax, read
  `references/terminal.md`.
- For live `cxd`/`ccd` delegation workflows, read `references/delegation.md`.
- For Codex-owned Nex indicator/status events, read
  `references/codex-status.md`.

## Quick Checks

```bash
nex --version
nex pane id
nex pane list --json
```

`nex pane id` exits `0` with a UUID when the shell is inside a Nex pane. Exit
`1` with empty output means it is not. Some Nex commands can silently no-op when
the app, socket, or pane context is unavailable, so reconcile with `pane list`
when state matters.
