---
name: nex-codex-status
description: "Use Nex event indicators for Codex-only status updates. Use when the user asks Codex to keep the Nex indicator/status updated, show Codex progress in Nex, or signal Codex task start, completion, failure, or notification through `nex event start|stop|error|notification`. Do not use for Claude Code lifecycle handling; Nex automates Claude Code lifecycle events."
---

# Nex Codex Status

Use Nex events to expose Codex task status in the Nex UI. Treat these events as best-effort status signals; they should not determine whether the user's actual task succeeds or fails.

## Workflow

1. For meaningful multi-step or long-running Codex work, start an indicator:

   ```bash
   nex event start --message "Brief Codex task label"
   ```

2. When the Codex task completes successfully, clear the indicator:

   ```bash
   nex event stop --message "Brief completion label"
   ```

3. If Codex cannot complete the task, signal an error before reporting the blocker:

   ```bash
   nex event error --message "Brief failure label" --title "Codex task failed" --body "One-line reason"
   ```

4. For user-visible attention after background or long-running work, send a notification:

   ```bash
   nex event notification --title "Codex update" --body "Brief status"
   ```

## Rules

- Use this skill for Codex's own status only.
- Do not emit `nex event session-start`.
- Do not manage Claude Code lifecycle events; Nex automates those.
- Do not wrap every small command. Signal meaningful task boundaries and user-visible transitions.
- Keep messages short, concrete, and human-readable.
- If `nex` is unavailable or an event command silently no-ops, continue the main task and mention the status-update failure only if it matters to the user.
