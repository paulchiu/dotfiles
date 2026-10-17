# Restarting Claude Code agents for an installed update

Restart the agent process in its existing pane, preserving its conversation.
Use `sessions.md` only for restarting a Herdr server; that kills all its panes.
Follow the current installed CLI help for syntax.

## Capture before exit

Resolve the intended session and socket, then discover the target pane there.
Keep that socket explicit on every command: pane IDs can repeat across servers.
Capture the pane ID, cwd, Claude session UUID, foreground process PID/version,
and argv as an array using `pane get` and `pane process-info`. Retain the agent
name and conversation title when available. Do not infer a UUID from the tab
label or use `--continue`, which may select another conversation.

Accept only a confirmed `idle` or `done` agent at an input prompt. Inspect its
visible screen and running tasks as well: an idle status does not prove that
background jobs have finished. Skip working, blocked, unknown, suspended or
unreadable targets. For a batch, prove exit and resume on one representative
pane first, as Paul requested, and recheck each remaining pane immediately
before changing it. Never include the orchestrator's own pane in its batch.

## Exit and resume

1. Preserve existing launch options, including permission mode, model, extra
   directories and configuration. Keep arguments as an array, not a joined
   shell string. Replace an old resume/continue selector with the captured
   `--resume <UUID>`; omit an old initial task prompt or one-shot execution
   options that would replay work. If an option's meaning is unclear, inspect
   it before exiting. Never add bypass flags or drop flags to make a retry work.
2. Inspect the current input before sending `/exit`. Do not blindly send Escape
   through a dialog or append text to an existing draft. If exit offers to stop
   tasks, ask unless Paul has explicitly authorised that loss. Accept a resume
   compact/compress choice only when authorised, after reading the exact option;
   a word match in the transcript is insufficient.
3. Confirm the old process exited and the foreground is the interactive shell
   before `agent start ... --kind claude --pane <pane> --timeout 60000 --
   <preserved-options> --resume <UUID>`. Do not start a second process merely
   because a read or wait timed out.
4. If start reports `agent_not_ready`, an agent may already be running at a
   dialog. Inspect process state and the visible screen before sending input
   or retrying. Stop on other errors and report the pane and recovery command.
   Do not retry by removing options or force-killing processes.
5. Verify the new process, expected installed version, same conversation UUID,
   and an actual ready input screen. Wait with a finite timeout for `idle` or
   `done` after an authorised dialog response. A running PID, missing update
   footer, or successful start alone does not prove the restart succeeded.

## Batch results and recovery

Use bounded concurrency only after the single-pane trial succeeds. Collect
per-pane outcomes: verified, skipped with reason, blocked, or failed with the
captured resume command. Propagate failures to the batch exit status and report
any pane left at a shell. Never print `OK` without completing verification.

The scripts left by the 2026-10-17 Pi run in sandbox
`outputs/herdr-orchestrator/restart-claude-update*.sh` are historical scratch
artifacts, not supported restart tools. They drop launch flags on fallback,
match dialogs by keywords, and do not verify conversation identity. Do not
reuse them without correcting those behaviours and validating the replacement.
