# Panes, layout, and ordinary commands

Use the pane surface for anything that is not a recognised coding agent:
shells, tests, dev servers, CI watchers, log tails. A pane exists whether or
not an agent occupies it. Pane input addresses the terminal regardless of its
current occupant; agent input resolves the live agent and refuses if that agent
no longer controls the pane.

## Discover live state

```bash
herdr workspace list
herdr tab list --workspace "$HERDR_WORKSPACE_ID"
herdr pane list --workspace "$HERDR_WORKSPACE_ID"
herdr pane current --current
herdr pane layout --current
herdr agent list
```

`herdr pane process-info --current` reports what actually owns the foreground,
which is how you confirm a pane is at its shell prompt.

## Create a pane

```bash
split=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus)
pane=$(printf '%s\n' "$split" | jq -r '.result.pane.pane_id')
```

`--ratio FLOAT` sets the split fraction. `--env KEY=VALUE` injects environment.
Creating a workspace also creates its first tab and root pane; creating a tab
creates its root pane. Use the returned pane for the first process and split
only when the layout genuinely needs another terminal.

## Run and observe

```bash
herdr pane run "$pane" "just test --watch"
herdr pane wait-output "$pane" --regex "passed|failed" --timeout 120000
herdr pane read "$pane" --source recent-unwrapped --lines 120
```

- `pane run` atomically sends the command text and Enter.
- `pane send-text` sends literal text with **no** Enter.
- `pane send-keys` sends logical keys and modifier chords.
- `pane wait-output` takes `--match TEXT` (literal substring) or `--regex
  PATTERN` (Rust regex, matched one line at a time). It does **not** interpret
  agent lifecycle.

**`wait-output` searches the snapshot immediately**, so text already on screen
matches straight away. If you are waiting for a *new* occurrence of something
already visible, match on something unique to this run.

Its default source is `recent`, covering the last 80 rendered rows. `--lines N`
changes that limit.

## Read sources

| Source | Use for |
| --- | --- |
| `recent-unwrapped` | Logs and transcripts. Joins soft wraps. The usual choice |
| `recent` | Recent rendered output, soft wraps intact |
| `visible` | Exactly what is on the viewport right now |
| `detection` | The plain-text bottom-buffer snapshot Herdr uses to classify agents |

Default output is UTF-8 with ANSI stripped. `--format ansi` preserves escapes
where the source exposes them; the detection source is always plain text.

For `recent` sources, `--lines N` selects the last N rendered rows and defaults
to 80. For `visible` and `detection`, omitting `--lines` returns the full
snapshot while specifying it keeps the last N newline-delimited lines.

If raising `--lines` stops revealing more of a completed response, the pane is
running a full-screen app on the alternate screen. Rows that leave the
alternate screen never enter Herdr's host scrollback, so no line count recovers
them. See the alternate-screen section in `delegation.md`.

Reads are passive. Herdr does not move the viewport for `visible`, `detection`,
ANSI reads, output waits, a manually scrolled agent, or a direct attachment.

## Rearrange

```bash
herdr pane focus  --direction right --current
herdr pane resize --direction right --amount 0.05 --current
herdr pane swap   --direction right --current
herdr pane zoom   --current --toggle
herdr pane rename "$pane" "test watcher"
herdr pane neighbor --direction right --current
```

Moving panes:

```bash
herdr pane move "$pane" --tab "$HERDR_TAB_ID" --split down --no-focus
herdr pane move "$pane" --new-tab --label logs --no-focus
herdr pane move "$pane" --new-workspace --label review --no-focus
```

**A move into another workspace changes the pane ID.** Continue with
`.result.move_result.pane.pane_id`. The old value is returned as
`.result.move_result.previous_pane_id` and stays valid only as an alias for the
moved process's own inherited `HERDR_PANE_ID`, so `--current` keeps working
inside it. Do not use the old ID as a general target.

## Right-click passthrough

Herdr owns right-click by default. For a pane running a mouse-reporting TUI:

```bash
herdr pane input --current --right-click pane
```

Right-click the pane frame to reach Herdr's own menu again. `pane split` accepts
`--right-click herdr|pane` to set this at creation.

## Closing

```bash
herdr pane close "$pane"
```

Only close panes you created. Closed pane and tab IDs are never reused.
