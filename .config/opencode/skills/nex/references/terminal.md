# Nex CLI Reference

Use this reference for exact Nex CLI syntax and common terminal-management
patterns.

Source of truth: `/Applications/Nex.app/Contents/Helpers/nex`.
Verified against Nex `0.22.0`.

## Version and Availability

```bash
nex --version
nex pane id
nex pane list [--workspace <name-or-id> | --current] [--json] [--no-header]
```

`pane list` is the best reconciliation command before sending to a named pane.
Use `--json` for scripts or structured checks.

## Panes

```bash
nex pane split [--direction horizontal|vertical] [--path /dir] [--name <label>] [--target <name-or-uuid>]
nex pane create [--path /dir] [--name <label>] [--target <name-or-uuid>]
nex pane close [--target <name-or-uuid>] [--workspace <name-or-uuid>]
nex pane name <name>
nex pane send --to <name-or-uuid> <command...>
nex pane move [left|right|up|down]
nex pane move-to-workspace --to-workspace <name-or-uuid> [--create]
nex pane list [--workspace <name-or-id> | --current] [--json] [--no-header]
nex pane capture [--target <name-or-uuid>] [--workspace <name-or-uuid>] [--lines N] [--scrollback]
nex pane id
```

Notes:

- `--workspace` and `--current` are mutually exclusive for `pane list`.
- `pane send` types text into the target PTY and presses Enter. If a shell is
  running, the text executes as shell input. If an agent is running, the text is
  sent as agent input.
- `pane send` exit `0` is not proof that text reached the PTY. When launching
  delegates, always verify with `pane capture`. If capture does not show the
  command or agent UI, retry once at most, then use the focused-pane fallback in
  `delegation.md`.
- `pane capture --lines N` is useful for checking whether a launch completed or
  whether an agent is waiting for input.

## Workspaces

```bash
nex workspace create [--name "Workspace Name"] [--path /dir] [--color blue] [--group <name>]
nex workspace move <name-or-id> (--group <name> | --top-level) [--index N]
```

`workspace create` opens the new workspace and gives it an initial shell pane in
Nex `0.22.0`. Verify before relying on focus-sensitive fallbacks:
`nex pane list --workspace "<name>" --json` should show the intended pane with
both `is_active_workspace: true` and `is_focused: true`.

`workspace move` requires either `--group <name>` or `--top-level`, but not both.
`--index` must be an integer when supplied.

## Groups

```bash
nex group create <name> [--color blue]
nex group rename <name-or-id> <new-name>
nex group delete <name-or-id> [--cascade]
```

## Layouts

```bash
nex layout cycle
nex layout select <name>
```

## Events

```bash
nex event start [--message "..."]
nex event stop [--message "..."]
nex event error [--message "..." --title "..." --body "..."]
nex event notification [--title "..." --body "..."]
nex event session-start [--message "..."]
```

For Codex-owned progress/status indicators, read `codex-status.md` before using
events.

## Open Files and Diffs

```bash
nex open [--here] <filepath>
nex diff [<path>]
```

Use `nex open --here <filepath>` when the file should open in the current pane
context.

## Examples

Set up a small dev workspace:

```bash
nex workspace create --name "Dev" --path ~/dev/project --color green
nex pane name "editor"
nex pane split --direction horizontal --name "server"
nex pane send --to "server" "npm run dev"
```

Capture recent pane output:

```bash
nex pane capture --target "server" --lines 80
```

Move a pane into a workspace, creating it if needed:

```bash
nex pane move-to-workspace --to-workspace "Debug" --create
```

Open the current diff:

```bash
nex diff
```
