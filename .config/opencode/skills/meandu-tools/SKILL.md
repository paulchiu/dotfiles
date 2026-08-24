---
name: meandu-tools
description: 'Router for me&u work tools. Rewrite a CUSM TypeORM-to-Prisma migration card; query Datadog via pup; regenerate GraphQL schema.gql after @Field changes; fix Redis 6379 "port already allocated" conflicts; generate the monthly Engineering On Call report.'
---

# meandu-tools (router)

Progressive-disclosure router. The actual instructions live in `nested/<task>/SKILL.md`. When the task matches a bullet below, Read that nested SKILL.md and follow it exactly.

## Dispatch table

- **Rewrite a CUSM TypeORM-to-Prisma migration card** (manage-api Phase 2, "swap Store internals") into an agent-ready card. Extends `linear-write` with governing docs, Mapped* decoupling, footgun sweep, write-path incident audits, stacked PR shape → `nested/rewrite-typeorm-migration-issue/SKILL.md`.
- **Datadog** via the `pup` CLI: search logs, query metrics, check monitors, investigate APM traces → `nested/pup-datadog/SKILL.md`.
- **Tiltfile modification in a git worktree**, NestJS `schema.gql` regeneration after `@Field` changes → `nested/worktree-tilt-schema/SKILL.md`.
- **Redis port 6379 conflict** ("port is already allocated", free port 6379; Docker or OrbStack) → `nested/fix-redis/SKILL.md`.
- **Monthly Engineering On Call report**, usually from the monthly Slack reminder or the Engineering On Call Notion runbook: run the GitHub report workflow for the previous month, check the CSV, prepare the Excel attachment, return plain email copy → `nested/generate-engineering-on-call-report/SKILL.md`.

If the request matches more than one, pick the most specific. If none match cleanly, ask the user which task they want.
