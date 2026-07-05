---
name: meandu-tools
description: 'Router for me&u work-tool wrappers. Use when: implementing/shipping a Linear issue end-to-end (ticket, code, commit, PR, CI; ship-it/auto/autonomous on a Linear URL or ID); creating or rewriting Linear issues with the agent-ready card template (incl. spikes); querying Buildkite builds/jobs/logs/pipelines/agents via bk CLI, or releasing/unblocking/promoting blocked Buildkite builds from URLs; querying Datadog metrics/logs/monitors/traces/APM via pup CLI; multi-perspective PR review orchestrator (security/performance/AC/style fan-out via codex or Claude subagents); generating the daily brief (Slack/Linear/Calendar/Drive/Obsidian) into today''s journal note; morning brief triage; regenerating GraphQL schema.gql in a NestJS Tiltfile worktree (after @Field changes); fixing Redis port 6379 / "port already allocated" conflicts (Docker or OrbStack).'
---

# meandu-tools (router)

Progressive-disclosure router. The actual instructions live in `nested/<task>/SKILL.md`. When the task matches a bullet below, Read that nested SKILL.md and follow it exactly.

## Dispatch table

- **Implement a Linear issue end-to-end** (ticket → code → commit → PR → CI), a Linear URL/ID with intent to implement, or **ship/ship-it/autonomously** (autonomous ticket-to-merge mode) → `nested/linear-do/SKILL.md`.
- **Create or rewrite a Linear issue** with the agent-ready card template, write a spike, clean up an issue from URL/ID → `nested/linear-write/SKILL.md`.
- **Buildkite** via the `bk` CLI: CI failures, build logs, retries, pipelines/jobs/agents; also **release / unblock / promote blocked builds** given `buildkite.com/...` URLs ("release these builds", "unblock these", "promote to prod", "push to prod") → `nested/bk-buildkite/SKILL.md`.
- **Datadog** via the `pup` CLI: search logs, query metrics, check monitors, investigate APM traces → `nested/pup-datadog/SKILL.md`.
- **Multi-perspective PR review orchestration**: given a PR number/URL, run the `review-code` baseline, fan out security / performance / acceptance-criteria / style perspectives in parallel (codex or Claude subagents, user picks), aggregate, post inline comments → `nested/pr-review-orchestrator/SKILL.md`.
- **Daily brief generation**: pull overnight signal from Slack, Linear, Google Calendar, Google Drive, and the Obsidian vault; write a structured brief to `Area/Journal/YYYY-MM-DD.md`. Triggers: `/daily-brief`, "run daily brief", "regenerate today's brief", or the 3am cron → `nested/daily-brief/SKILL.md`.
- **Morning triage**: walk through today's brief item by item (file ticket / mark done / defer / draft Slack reply / discuss). Triggers: `/morning`, "morning", "let's triage", "walk me through today" → `nested/morning/SKILL.md`.
- **Tiltfile modification in a git worktree**, NestJS `schema.gql` regeneration after `@Field` changes → `nested/worktree-tilt-schema/SKILL.md`.
- **Redis port 6379 conflict** ("port is already allocated", free port 6379; Docker or OrbStack) → `nested/fix-redis/SKILL.md`.

If the request matches more than one, pick the most specific. If none match cleanly, ask the user which task they want.
