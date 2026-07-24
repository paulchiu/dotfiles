# Nex CLI Reference

Use this reference for exact Nex CLI syntax and common terminal-management
patterns.

Source of truth: `/Applications/Nex.app/Contents/Helpers/nex`.
Verified against Nex `0.23.0`.

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
nex pane send [--bare] --target <name-or-uuid> [--workspace <name-or-uuid>] <command...>
nex pane send-key --target <name-or-uuid> <key>   # e.g. Return
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
Nex `0.23.0`. Verify before relying on focus-sensitive fallbacks:
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

### Group-scoped pane operations (broadcast)

The CLI does not expose group membership on `pane list`, and there is no
`--group` filter. To act on all panes in a group (e.g. send `/compact` to every
Claude pane in "Side quests"), join SQLite group data with `pane list --json`.

`workspace_group.childOrderJSON` in `~/Library/Application Support/Nex/nex.db`
holds the ordered workspace IDs for each group. The pane list JSON includes
`workspace_id`, `claude_session_id` (set when Claude Code is running), and the
title prefix `✳`/`✶`/`⠐` (set while an agent is active).

Reusable broadcast pattern (replace `GROUP`, `AGENT_FILTER`, and `MSG`):

```bash
GROUP="Side quests"
# Agent filter examples:
#   Claude only:      select(.claude_session_id != null)
#   Any agent pane:   select(.title | startswith("✳") or startswith("✶") or startswith("⠐"))
#   All panes:        .  (omit select)
AGENT_FILTER='select(.claude_session_id != null)'
MSG="/compact"

WS_IDS=$(sqlite3 "$HOME/Library/Application Support/Nex/nex.db" \
  "SELECT childOrderJSON FROM workspace_group WHERE name='$GROUP';")
PANE_IDS=$(nex pane list --json | jq -r --argjson ws "$WS_IDS" \
  ".[] | . as \$p | $AGENT_FILTER | select(\$ws | index(\$p.workspace_id) != null) | .id")

for id in $PANE_IDS; do
  nex pane send --target "$id" "$MSG"
done
```

Notes:

- Match on `workspace_group.name` is case-sensitive in SQLite by default; add
  `COLLATE NOCASE` if needed.
- `childOrderJSON` is a JSON array of workspace UUID strings, so it passes
  directly to `jq --argjson ws`.
- `pane send` typing the slash command lands as agent input when an agent is
  the foreground process. Verify with `nex pane capture --target <id> --lines 20`
  on at least one pane before assuming the broadcast worked.
- Text sitting unsubmitted in a pane's input box (the `❯` line) is often a
  queued draft, not live composer input: Paul (or a prior orchestration) may
  have typed several messages ahead, and the box shows the next one. Do not
  assume it is a single un-sent line.
- `nex pane send-key --target <id> enter` (or `return`) does NOT reliably submit
  such a draft. On an idle or non-focused pane the keystroke is acked ("sent
  enter to ...") but no-ops: the draft neither submits nor edits, and even
  `backspace`/`escape` leave it unchanged. Do not trust a `0` exit here.
- The reliable submit is `nex pane send --target <id> "<text>"`. It writes the
  text and Enter together into the composer and submits. Crucially it REPLACES
  the drafted message with `<text>` (it does not append), so pass the exact full
  instruction you want run, and do NOT pre-write with `--bare` first (a prior
  `--bare` write stays in the composer and gets prefixed onto your text).
- After submitting, verify with `nex pane capture`: the `❯` box should clear and
  the agent should show activity. Note that submitting one draft surfaces the
  next queued message in the box, so re-capture before deciding you are done; do
  not blindly re-fire, which would consume a queue the user built.
- Valid `send-key` keys: `enter, return, tab, escape, esc, space, backspace, up,
  down, left, right, ctrl-c`.
- The mid-transition swallow (e.g. a pane just finishing `/compact` and
  restoring skills) is a real but narrower case; the `nex pane send <text>`
  re-issue above is the general fix, not `send-key`.
- For agent detection, `claude_session_id` is the most reliable signal for
  Claude panes. Codex panes do not currently expose an analogous field; fall
  back to the title-prefix filter when targeting any running agent.

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

## Web View

```bash
nex web open [--private] <url>
nex web reload [--target <name-or-uuid>] [--workspace <name-or-uuid>] [--hard]
nex web url|back|forward [--target <name-or-uuid>] [--workspace <name-or-uuid>]
nex web capture [--target <name-or-uuid>] [--mode meta|text|screenshot]
```

`nex web open` creates a web-view pane in the current workspace and prints the
new pane UUID. To preview a local HTML file, pass a `file://` URL with spaces
percent-encoded (`%20`), for example
`nex web open "file:///Users/paul/dev/sandbox/outputs/2026-05-30%20My%20Doc.html"`.
After editing the file, refresh with `nex web reload --target <uuid> --hard`.

Gotcha: the web view does NOT reliably honour `prefers-color-scheme: dark`, and
it can render against a dark Nex chrome, so a light-themed page (or the light
half of a `@media (prefers-color-scheme: dark)` stylesheet) shows up as
low-contrast grey-on-white. When generating HTML for Paul to read or comment on
in a web pane, default to an explicit dark theme with hardcoded colours
(`color-scheme: dark`, dark background, near-white text), rather than relying on
media-query auto-switching.

## Examples

Set up a small dev workspace:

```bash
nex workspace create --name "Dev" --path ~/dev/project --color green
nex pane name "editor"
nex pane split --direction horizontal --name "server"
nex pane send --target "server" "npm run dev"
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
