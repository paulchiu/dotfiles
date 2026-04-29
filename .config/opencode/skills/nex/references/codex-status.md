# Nex Codex Status

Use this reference when the user asks Codex to keep Nex status indicators
updated, show Codex progress in Nex, or send a Nex notification for Codex work.

These events are best-effort UI signals. They must not determine whether the
actual task succeeds or fails.

## Workflow

Start a meaningful multi-step or long-running Codex task:

```bash
nex event start --message "Brief Codex task label"
```

Clear the indicator when the Codex task completes:

```bash
nex event stop --message "Brief completion label"
```

Signal a failure before reporting the blocker:

```bash
nex event error --message "Brief failure label" --title "Codex task failed" --body "One-line reason"
```

Send a user-visible notification after background or long-running work:

```bash
nex event notification --title "Codex update" --body "Brief status"
```

## Rules

- Use these events for Codex's own status only.
- Do not emit `nex event session-start` for Codex status; Nex handles agent
  lifecycle events separately.
- Do not wrap every small command. Signal meaningful task boundaries and
  user-visible transitions.
- Keep messages short, concrete, and human-readable.
- If `nex` is unavailable or an event command silently no-ops, continue the main
  task. Mention the status-update failure only if it matters to the user.
