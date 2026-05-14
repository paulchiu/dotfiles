---
name: meandu-tools
description: Router for me&u work-tool wrappers. Use when implementing/working on a Linear issue end-to-end (read ticket, code, commit, open PR, monitor CI), or shipping/ship-it/auto/autonomous on a Linear URL or ID; creating or rewriting Linear issues using the agent-ready card template (including spikes); querying Buildkite builds/jobs/logs/pipelines/agents via the bk CLI for CI failures or build retries; querying Datadog metrics/logs/monitors/traces/APM via the pup CLI; running a multi-perspective PR review orchestrator that fans out security/performance/acceptance-criteria/style passes against a shared branch-review baseline via codex or Claude subagents; generating an automated daily brief (Slack/Linear/Calendar/Drive/Obsidian cross-referenced) into today's journal note; triaging the brief conversationally in the morning; regenerating GraphQL schema.gql in a NestJS Tiltfile worktree (after @Field changes); or fixing Redis port 6379 / "port already allocated" conflicts for Docker or OrbStack.
---

# meandu-tools (router)

Progressive-disclosure router. The actual instructions live in `nested/<task>/SKILL.md` files. When the task matches one of the bullets below, Read that nested SKILL.md and follow its instructions exactly.

## Dispatch table

- **Implement a Linear issue end-to-end** (read ticket → code → commit → PR → CI), or given a Linear URL/ID with intent to do/implement, or asked to **ship/ship-it/autonomously** an issue (autonomous ticket-to-merge mode) → Read `nested/linear-do/SKILL.md`.
- **Create or rewrite a Linear issue** using the agent-ready card template, write a spike, clean up an issue from URL/ID → Read `nested/linear-write/SKILL.md`.
- **Buildkite**: investigate CI failures, read build logs, retry builds, query pipelines/jobs/agents via the `bk` CLI → Read `nested/bk-buildkite/SKILL.md`.
- **Datadog**: search logs, query metrics, check monitors, investigate APM traces via the `pup` CLI → Read `nested/pup-datadog/SKILL.md`.
- **Multi-perspective PR review orchestration**: given a PR number/URL, run the `reviewing-branch-changes` baseline then fan out security / performance / acceptance-criteria / style perspectives in parallel (codex or Claude subagents, user picks at invocation), aggregate, post inline comments, only ping on blockers or disagreements → Read `nested/pr-review-orchestrator/SKILL.md`.
- **Daily brief generation**: pull overnight signal from Slack (unread mentions, threads), Linear (assigned/subscribed/overnight changes), Google Calendar (today), Google Drive (last 24h shared), and the Obsidian vault (open action items); cross-reference for bug reports without Linear tickets, prep gaps, and overdue 1:1 commitments; write a structured brief to `Area/Journal/YYYY-MM-DD.md`. Triggers: `/daily-brief`, "run daily brief", "regenerate today's brief", or invoked from the 3am cron → Read `nested/daily-brief/SKILL.md`.
- **Morning triage**: walk through today's brief item by item conversationally — file ticket / mark done / defer / draft Slack reply / discuss. Triggers: `/morning`, "morning", "let's triage", "walk me through today" → Read `nested/morning/SKILL.md`.
- **Tiltfile modification in a git worktree, NestJS schema.gql regeneration, GraphQL schema rebuild after @Field changes** → Read `nested/worktree-tilt-schema/SKILL.md`.
- **Redis port 6379 conflict / "port is already allocated" / free port 6379** (Docker or OrbStack) → Read `nested/fix-redis/SKILL.md`.

If the request matches more than one, pick the most specific match. If none match cleanly, ask the user which task they want.
