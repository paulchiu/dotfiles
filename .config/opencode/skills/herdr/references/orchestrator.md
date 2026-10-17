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
- **Stay in the current workspace and tab** for anything you set up unless the
  work genuinely needs another one.

## Ownership and approval

- **Never close a pane, tab, workspace, or session you did not create**, unless
  Paul explicitly asks. Closed IDs are never reused.
- **Bring `blocked` states and approval dialogs back to Paul.** Never answer an
  approval dialog, login, or trust prompt on his behalf. Read it, report it, ask.
- **Do not post, reply, or draft on Paul's behalf** in Slack, Gmail, or any other
  communication channel.

## Prompting workers

- **Every worker prompt carries guardrails:** its scope, the files or
  responsibilities it owns, and an instruction not to revert another agent's or
  Paul's changes. Give concurrent agents disjoint ownership.
- **Target explicitly** — `--current`, a pane ID, or a unique agent name. Never
  let a prompt fall through to the UI-focused pane, which may be Paul's.
- **Always pass `--timeout` and `--no-focus`** for background work, and preserve
  cwd on every split with `--cwd "$PWD"`.
- Read back with `agent read <target> --source recent-unwrapped`, and relay a
  distilled result rather than a wall of transcript.

## Naming convention

- **A tab's label matches the agent's session name.** Rename the agent to match
  the tab (`/rename` on a Claude agent) so Paul can navigate by the tab bar.
- Tab labels may carry status markers where a pipeline defines them; drop those
  markers from the agent's session name.

## Reporting to Paul

- Paul often reads from another device. Relay results in chat and, when the
  deliverable is a file, push the file rather than only naming its path.
- Lead with the outcome and the decision he needs to make, not the mechanics.

## Layout state

- **Derive the layout at run time; never trust a cached ID.** Ask the live
  session:

  ```bash
  herdr workspace list
  herdr tab list  --workspace "$HERDR_WORKSPACE_ID"
  herdr pane list --workspace "$HERDR_WORKSPACE_ID"
  herdr agent list
  ```

- A **gitignored, ephemeral snapshot** may exist at
  `outputs/herdr-orchestrator/layout.md` in the sandbox repo as a rough
  orientation aid. It is not authoritative and it goes stale in days. Re-read
  it, verify every ID against the live commands above, then **refresh it** when
  the layout changes. Never put a layout snapshot into this skill or into a
  committed doc; it is regenerable working state, not a record.

## Standing constraints

These are Paul's standing rules for orchestrated work:

- SELECT-only data access.
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
- Server lifecycle, named sessions, remote attach, config, install:
  `sessions.md`.
