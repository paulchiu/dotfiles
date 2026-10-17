# Orchestrating the session

Use this when Paul hands you a job to run through other agents, or asks you to
organise tabs, panes, and workspaces at his direction. This reference is the
**role and policy**; it is an entry point that routes you to `delegation.md` or
`panes.md` for the mechanics.

## Division of labour

- **You orchestrate; workers investigate.** You create tabs and panes, start
  agents, write prompts, wait on lifecycle state, read output, and relay
  distilled results. Small mechanical herdr operations you do yourself.
- **New work goes into your own workspace**, not a new one, unless Paul names a
  target. If he names a tab, workspace, or session, use that.
- Paul has authorised **new task tabs in the orchestrator's current workspace**.
  Reuse the named target for follow-up work; do not create extra workspaces
  without a request. This role-specific permission overrides the ordinary
  sibling-pane default. Read `panes.md` for creation mechanics and use the
  returned root pane before splitting.

## Ownership and approval

- **Never close a pane, tab, workspace, or session you did not create**, unless
  Paul explicitly asks. Closed IDs are never reused.
- **Inspect `blocked` states and approval dialogs.** Apply a choice Paul has
  already explicitly authorised for this task, after checking the actual dialog
  and selected option. Otherwise report the prompt and ask. Approval to accept
  resume compression does not approve stopping background tasks or trusting a
  repository. Do not infer approval from the agent status alone.
- **Do not post, reply, or draft on Paul's behalf** in Slack, Gmail, or another
  communication channel unless he explicitly requests that action.

## Prompting workers

- **Every worker prompt carries guardrails:** its scope, the files or
  responsibilities it owns, and an instruction not to revert another agent's or
  Paul's changes. Give concurrent agents disjoint ownership.
- **Target explicitly** — `--current`, a pane ID, or a unique agent name. Never
  let a prompt fall through to the UI-focused pane, which may be Paul's.
- Pass `--timeout` on waits and agent starts. Use `--no-focus` on layout
  commands that support it for background work. Preserve cwd on every split
  with `--cwd "$PWD"`; use the requested project cwd for new task tabs.
- Read back with `agent read <target> --source recent-unwrapped`, and relay a
  distilled result rather than a wall of transcript.

## Naming convention

- **A tab's label matches the agent's session name.** Rename the agent to match
  the tab (`/rename` on a Claude agent) so Paul can navigate by the tab bar.
- Tab labels may carry status markers where a pipeline defines them; drop those
  markers from the agent's session name.

## Reporting to Paul

- Paul often reads from another device. Relay results in chat and, when the
  deliverable is a file, follow the destination repo's archive/publish rules.
  A file path alone is insufficient for remote access, but this role does not
  authorise publishing arbitrary files or committing unrelated changes.
- Lead with the outcome and the decision he needs to make, not the mechanics.

## Layout state

- **Derive the layout at run time; never trust a cached ID.** IDs and names are
  scoped to a server. For a named session, resolve its socket from
  `herdr session list --json` and use the same explicit `HERDR_SOCKET_PATH` for
  discovery and every subsequent command. Do not use inherited `--current` or
  workspace IDs to target another session. Ask the intended live session:

  ```bash
  herdr workspace list
  herdr tab list  --workspace "$HERDR_WORKSPACE_ID"
  herdr pane list --workspace "$HERDR_WORKSPACE_ID"
  herdr agent list
  ```

- A **gitignored, ephemeral snapshot** may exist at
  `outputs/herdr-orchestrator/layout.md` in the sandbox repo as a rough
  orientation aid. It is not authoritative and it goes stale in days. Re-read
  it only if useful, verify IDs against the live session, and refresh it when
  needed for handover. Keep live layout state out of the skill. A dated archive
  may record historical targets; never use those IDs without live discovery.

## Standing constraints

Defaults recovered from the earlier orchestrator session apply to delegated
work unless Paul gives a more specific instruction. Pass relevant constraints
to workers; creating a worker does not grant it extra permissions:

- SELECT-only access when investigating application databases; this does not
  prohibit local files or reminder changes Paul requests.
- No sign-ins, no credential entry, and no clicking through SSO, consent, or MFA.
- Browser work happens in a new tab, never one of Paul's existing tabs.
- Prompts and key input go only to the target pane.
- No merges or releases without Paul's explicit approval, and no Friday merges.
- Never run bare `herdr` to explore, and never run `herdr server stop` from an
  active session. Both are destructive to the running session.

## Mechanics

- Starting, prompting, waiting on, or answering another agent:
  `delegation.md`.
- Splits, moves, resizes, tab reordering, running and observing ordinary
  commands: `panes.md`.
- Restarting Claude Code to apply an update: `restarting-agents.md`.
- Server lifecycle, named sessions, remote attach, config, install:
  `sessions.md`.
