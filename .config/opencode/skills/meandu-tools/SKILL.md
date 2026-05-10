---
name: meandu-tools
description: Router for me&u work-tool wrappers. Use when implementing/working on a Linear issue end-to-end (read ticket, code, commit, open PR, monitor CI), or given a Linear URL/ID with intent to implement; creating or rewriting Linear issues using the agent-ready card template (including spikes); querying Buildkite builds/jobs/logs/pipelines/agents via the bk CLI for CI failures or build retries; querying Datadog metrics/logs/monitors/traces/APM via the pup CLI; or running a multi-perspective PR review orchestrator that fans out security/performance/acceptance-criteria/style passes against a shared branch-review baseline via codex or Claude subagents.
---

# meandu-tools (router)

Progressive-disclosure router. The actual instructions live in `nested/<task>/SKILL.md` files. When the task matches one of the bullets below, Read that nested SKILL.md and follow its instructions exactly.

## Dispatch table

- **Implement a Linear issue end-to-end** (read ticket → code → commit → PR → CI), or given a Linear URL/ID with intent to do/implement → Read `nested/linear-do/SKILL.md`.
- **Create or rewrite a Linear issue** using the agent-ready card template, write a spike, clean up an issue from URL/ID → Read `nested/linear-write/SKILL.md`.
- **Buildkite**: investigate CI failures, read build logs, retry builds, query pipelines/jobs/agents via the `bk` CLI → Read `nested/bk-buildkite/SKILL.md`.
- **Datadog**: search logs, query metrics, check monitors, investigate APM traces via the `pup` CLI → Read `nested/pup-datadog/SKILL.md`.
- **Multi-perspective PR review orchestration**: given a PR number/URL, run the `reviewing-branch-changes` baseline then fan out security / performance / acceptance-criteria / style perspectives in parallel (codex or Claude subagents, user picks at invocation), aggregate, post inline comments, only ping on blockers or disagreements → Read `nested/pr-review-orchestrator/SKILL.md`.

If the request matches more than one, pick the most specific match. If none match cleanly, ask the user which task they want.
