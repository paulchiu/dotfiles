# Delegating to another agent

The whole point of the agent surface: you can wait until another agent is
*genuinely* blocked or settled, instead of firing keystrokes and sleeping.

Supported kinds (confirm against `herdr agent`, the list moves):
`pi claude codex gemini cursor devin agy cline omp mastracode opencode copilot
kimi kiro droid amp grok hermes kilo qodercli qwen maki`

## Step 1: Create a sibling pane

`agent start` requires an existing shell pane and **never creates, splits, or
moves layout**. That is the pane surface's job, so make the pane first.

Pick a direction from the caller's geometry unless the user asked for one:

```bash
herdr pane layout --pane "$HERDR_PANE_ID"
```

Split a wide pane `right`, a narrow or tall pane `down`. Avoid repeated
same-direction splits that produce unusably narrow columns.

```bash
split=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus)
worker=$(printf '%s\n' "$split" | jq -r '.result.pane.pane_id')
```

The new pane must be sitting at its interactive shell prompt before step 2:
the shell itself in the foreground, no command, editor, or agent running.

## Step 2: Start the agent

Names must match `[a-z][a-z0-9_-]{0,31}` and be unique among live agents. The
name is an alias for the current occupant of that pane, not a permanent rename;
it clears when the agent exits, is released, or is replaced.

```bash
herdr agent start reviewer --kind codex --pane "$worker" --timeout 60000
```

Native agent arguments go after `--`, unchanged:

```bash
herdr agent start reviewer --kind codex --pane "$worker" -- -m gpt-5.4
```

`agent start` returns only once Herdr has detected the agent in that pane and
considers it ready for input. Startup defaults to 30s; `--timeout` accepts
3001 to 300000 ms.

If it returns `agent_not_ready`, the agent came up **blocked** (a trust prompt,
a login, a model picker). The name still works for `agent read` and
`agent send-keys`. Read the pane, clear the dialog, and wait for idle before
prompting.

## Step 3: Prompt it

```bash
herdr agent prompt reviewer "Review the current diff. Report only actionable findings." \
  --wait --timeout 120000
```

`agent prompt` sends the text plus an encoded Enter, honouring the pane's live
bracketed-paste mode.

- If the agent is **already blocked**, it returns `agent_blocked` and sends
  **nothing**. Inspect the dialog and ask the user before answering it.
- `--wait` alone waits for the first settled state: `idle`, `done`, or
  `blocked`. Do not restate those with `--until`.
- An accepted prompt must produce an observed lifecycle change within 5s, or
  you get `agent_prompt_stalled` rather than an indefinite wait.
- The wait tracks lifecycle state, **not turns**. If the agent was already
  working, completion of that in-flight turn can satisfy your wait.

Use `--until` only for a state-specific workflow, such as catching an
already-running agent when it asks for input:

```bash
herdr agent wait reviewer --until blocked --timeout 120000
```

Repeat the flag to accept several: `--until idle --until done`.

## Step 4: Read the result

```bash
herdr agent get reviewer
herdr agent read reviewer --source recent-unwrapped --lines 120
```

Prefer `recent-unwrapped` for transcripts and logs: it joins soft wraps.
`--format ansi` only when colour is the evidence.

**Alternate-screen limit.** Full-screen agents (Claude Code, opencode) render
history in the terminal's alternate screen, not Herdr's host scrollback. Herdr
will scroll the agent's own mouse interface to page through it, but only while
the agent is **idle** and at the bottom of its transcript. Asking for more
lines than the viewport while it is working, blocked, or unknown returns
`agent_not_idle`. Wait for idle and retry, or use `--source visible`.

If a complete response is still unreachable, ask the agent to write it as
Markdown to a temp path and reply with only that path, then read the file.
Use this as a fallback; do not bake it into the first prompt.

## Answering a blocked agent

```bash
herdr agent wait reviewer --until blocked --timeout 120000
herdr agent read reviewer --source recent-unwrapped --lines 80
herdr agent send-keys reviewer esc
```

`send-keys` takes logical keys (`esc`/`escape`, `enter`, `up`, `down`,
`ctrl+c`). Herdr validates every key before writing any bytes. Use it for UI
interaction; use `agent prompt` for text work.

Do not answer an approval dialog on the user's behalf. Read it, report it, ask.

## Lifecycle states

| State | Meaning |
| --- | --- |
| `working` | Actively running |
| `blocked` | Herdr recognised an approval or question UI |
| `done` | Finished, and the tab has not been seen in the focused UI yet |
| `idle` | Ready for input, and has been seen |
| `unknown` | An agent is present but Herdr cannot classify it. **Not** proof of success |

`done` and `idle` are the same underlying state; the difference is whether the
tab has been focused. CLI reads do **not** mark it seen, only focusing the tab
or `pane focus` / `agent focus` does. Use exact `--until` states when that
distinction matters.

When a state looks wrong, `herdr agent explain <target> --verbose` reports how
Herdr classified it.

## Coordination

- One agent per pane. Address it by name or by the pane ID hosting it. Agent
  commands reject terminal IDs and bare kind labels.
- Give each concurrent agent explicit file or responsibility ownership, and
  tell it not to revert another agent's or the user's changes.
- After a `pane move`, the pane ID changes. Continue with
  `.result.move_result.pane.pane_id` or the live agent name. A wait already in
  flight ends with `agent_not_running`.
