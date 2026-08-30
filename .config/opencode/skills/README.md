# Skills

Agent skills loaded by Claude Code and Codex. This directory is the source of
truth; `~/.claude/skills` and `~/.agents/skills` are symlinks to it, so both
harnesses see the same set. Changes are tracked in `yadm` (`feat(skills):` for
a new skill, `feat(<skill-name>):` for a change inside one).

Each skill is a directory holding a `SKILL.md`, an `agents/openai.yaml` for the
Codex picker, and optionally `references/` (material loaded on demand) or
`nested/` (sub-skills behind a router).

25 skills. `.system/` holds vendor skills shipped with Codex and is not listed
here.

## Ship code

| Skill | What it does |
| --- | --- |
| [`dispatch`](dispatch/SKILL.md) | Orchestrates a codex implementation run with a separate adversarial Claude review, a watchdog loop, and a push/CI stage. |
| [`ship`](ship/SKILL.md) | Takes a Linear issue from ticket to merged, with an autonomous mode and a decision log. |
| [`review-code`](review-code/SKILL.md) | Multi-round PR or branch review (principal-engineer, adversarial, optional persona and Codex rounds) producing a decision doc. |
| [`tuicr`](tuicr/SKILL.md) | Opens a PR or a local branch diff in the tuicr review TUI, and drives a review session as an agent. |
| [`gh-pr`](gh-pr/SKILL.md) | Writes a PR description from the current branch and opens the draft PR. |
| [`git-commit`](git-commit/SKILL.md) | Writes a conventional commit message from the diff and creates the commit. |
| [`linear-write`](linear-write/SKILL.md) | Creates or rewrites Linear issues into agent-ready cards. |
| [`implementation-guidance-generator`](implementation-guidance-generator/SKILL.md) | Generates Obsidian-style implementation guidance docs for an issue, bug, or feature. |

## Understand code

| Skill | What it does |
| --- | --- |
| [`codebase-memory`](codebase-memory/SKILL.md) | Queries the codebase knowledge graph for callers, call chains, dependencies, dead code, and impact. |
| [`ast-grep`](ast-grep/SKILL.md) | Structural (AST) code search and rewrite, for when regex is the wrong tool. |

## Build on platforms

| Skill | What it does |
| --- | --- |
| [`cloudflare`](cloudflare/SKILL.md) | Router for the Cloudflare platform: Workers, Pages, KV/D1/R2, Vectorize, WAF, Wrangler, Durable Objects, and more. |
| [`bk-buildkite`](bk-buildkite/SKILL.md) | Manages Buildkite builds, jobs, logs, and pipelines; unblocks and releases to production. |
| [`frontend-design`](frontend-design/SKILL.md) | Builds web components, pages, and apps with high design quality. |

## Terminal

| Skill | What it does |
| --- | --- |
| [`herdr`](herdr/SKILL.md) | Manages Herdr panes, workspaces, and tabs, and delegates work to live agent panes. |

## Write and convert

| Skill | What it does |
| --- | --- |
| [`writing-tone`](writing-tone/SKILL.md) | Writes, rewrites, and summarises Slack messages, email, and updates in Paul's voice. |
| [`notion-doc-review`](notion-doc-review/SKILL.md) | Reviews a Notion page or other prose document. |
| [`dated-doc-renamer`](dated-doc-renamer/SKILL.md) | Renames documents to the `yyyy-mm-dd Title.md` convention, preserving acronym casing. |
| [`markitdown-convert`](markitdown-convert/SKILL.md) | Converts PDF, Word, PowerPoint, Excel, image, audio, HTML, CSV, JSON, XML, ZIP, and EPUB files to Markdown. |
| [`html-edit-prompt`](html-edit-prompt/SKILL.md) | Adds an annotation and comment layer to an HTML file so it can be marked up. |
| [`branded-deck-builder`](branded-deck-builder/SKILL.md) | Builds decks, bento slides, and Wrapped-style animations in the me&u engineering visual style. |

## Day to day

| Skill | What it does |
| --- | --- |
| [`daily-brief`](daily-brief/SKILL.md) | Generates the work daily brief from calendar, Slack, Linear, Gmail, and Drive. |
| [`reviewing-candidates`](reviewing-candidates/SKILL.md) | Reviews candidate resumes and interview transcripts, and drafts hiring feedback. |
| [`yadm-sync`](yadm-sync/SKILL.md) | Commits and pushes dotfile changes under `~/.claude` and `~/.config` with yadm. |

## Domain routers

Thin dispatch tables. The instructions live in `nested/<task>/SKILL.md` and load
only once the router picks a task.

| Skill | What it does |
| --- | --- |
| [`meandu-tools`](meandu-tools/SKILL.md) | me&u work: CUSM migration cards, Datadog via pup, GraphQL schema regeneration, Redis port conflicts, the on-call report. |
| [`personal`](personal/SKILL.md) | Personal life: the ANZ money report, PocketSmith, Obsidian archiving, Taiwan Chinese translation, ebook naming, aichat roles. |
