---
name: nex-agent-bridge
description: Set up and operate a two-agent Nex workflow where Codex and Claude Code run in separate panes and exchange work through shared mailbox files plus `nex pane send` wake-up messages. Use when the user wants one Codex agent and one Claude Code agent to collaborate, relay questions or answers between panes, bootstrap a bridge script, or manage turn-based coordination inside Nex.
---

# Nex Agent Bridge

Use this skill to create a stable bridge between one Codex pane and one Claude Code pane inside Nex.

Prefer a shared mailbox protocol over direct pane-to-pane chat. `nex pane send` types into the target PTY, so raw agent-to-agent messaging is brittle if the target pane is mid-command, at a shell prompt, or drawing a TUI. Shared files make the exchange deterministic; Nex is only the wake-up transport.

## Prerequisites

- Run inside Nex. Verify `echo $NEX_PANE_ID` is non-empty.
- Ensure both `nex`, `codex`, and `claude` are on `PATH`.
- Start from the workspace root both agents should share.

## Bootstrap

Use the bundled script:

```bash
./scripts/start_bridge.sh /path/to/worktree
```

The script:

- names the current pane `coordinator`
- creates a right-hand worker column by splitting the coordinator pane once
- creates the `claude` pane by splitting the `codex` pane before either agent starts
- creates `.nex-mail/`
- starts Codex and Claude Code in their panes
- primes each agent with the mailbox protocol

Environment variables supported by `scripts/start_bridge.sh`:

- `COORDINATOR_NAME`
- `CODEX_NAME`
- `CLAUDE_NAME`
- `CODEX_FLAGS`
- `CLAUDE_FLAGS`
- `MAIL_DIR`
- `POLL_INTERVAL`
- `SPLIT_DELAY`
- `LAYOUT`

By default the script preserves the explicit split tree and does not call `nex layout select`. Set `LAYOUT` only if you explicitly want Nex to rearrange the pane tree. Valid layouts in the current Nex CLI are:

- `tiled`
- `even-horizontal`
- `even-vertical`
- `main-horizontal`
- `main-vertical`

By default the bridge starts:

- Codex with `--dangerously-bypass-approvals-and-sandbox`
- Claude Code with `--dangerously-skip-permissions`

Override either with `CODEX_FLAGS` or `CLAUDE_FLAGS` if you want a safer mode for a specific run.

Each worker pane runs a polling loop from `scripts/agent_loop.sh`. The loop watches its inbox file, invokes the agent non-interactively for each new message, and writes a single reply into the peer outbox. `POLL_INTERVAL` defaults to `2` seconds.

## Mailbox Protocol

Use these shared files:

- Codex inbox: `.nex-mail/to-codex.md`
- Claude inbox: `.nex-mail/to-claude.md`

Each worker loop writes exactly one reply to the peer inbox when its inbox file changes:

```bash
printf '%s\n' 'Review the latest plan and answer the open question.' | ./scripts/post_message.sh claude -
printf '%s\n' 'Claude replied in .nex-mail/to-codex.md. Resolve the blocking decision.' | ./scripts/post_message.sh codex -
```

No explicit `CHECK_INBOX` wake-up message is required.

## Operating Rules

- Keep one coordinator pane. Do not let the peers free-run against each other.
- Treat Nex as transport only. Treat `.nex-mail/` as the source of truth.
- Keep prompts explicit: tell the target agent to read its inbox, answer once, and stop.
- Overwrite inbox files instead of appending unless you explicitly want cumulative context.
- If an agent drifts, restate the protocol in the next inbox message rather than trying to repair a half-finished PTY exchange.

## Recommended Use Cases

- Ask Claude for a review while Codex implements.
- Ask Codex to apply or verify a change proposed by Claude.
- Run structured back-and-forth on one narrow question with a coordinator relaying turns.

## Avoid

- Directly piping one interactive agent's terminal output into another pane.
- Long autonomous loops without coordinator oversight.
- Assuming `nex pane send` is reliable enough to act as a full duplex chat channel.
