---
name: ai-pril-manage-unblock-progress-reports
description: "Regenerates the four 2026 AI-pril Manage-Unblock daily progress reports (TypeORM→Prisma, Vulnerability Remediation, Form Library Migration, Formik+Yup→RHF+Zod) and the consolidated Clean Kitchen snapshot in Notion. Queries Linear for current ticket state per workstream, then overwrites each Notion page (callout on each says the page is overwritten daily, with history preserved). Use when the user asks to regenerate, refresh, or update the AI-pril progress reports, the Manage-Unblock reports, the Clean Kitchen progress reports, the daily snapshot, or 'the reports'. Also covers: 'run the daily update', 'redo yesterday's progress report', 'notion agent messed up the reports, please re-run'."
---

# 2026 AI-pril Manage-Unblock Progress Reports

Regenerate the four 2026 AI-pril Manage-Unblock detail progress reports plus the consolidated Clean Kitchen snapshot in Notion, using Linear as the source of truth for current ticket state.

## Report date determination

Determine the report date before launching any subagents.

1. If the user passed a date in the skill args (e.g. `2026-04-21`, `yesterday`, `today`), use that.
2. Otherwise read the current local time (via `Bash: date +%H`):
   - Hour `>= 12` (noon or later): **report date = today**.
   - Hour `< 9` (before 9am): **report date = yesterday** (today minus 1 calendar day).
   - `9 <= hour < 12`: **ask the user** with AskUserQuestion. Options: "today (YYYY-MM-DD)" and "yesterday (YYYY-MM-DD)". Do not pick unilaterally in this window.

Compute `today` and `yesterday` with `date -v-1d +%Y-%m-%d` (BSD/macOS) or `date -d 'yesterday' +%Y-%m-%d`. Never guess.

## Pages to regenerate

Hardcoded page IDs. The pages are expected to live at these locations indefinitely.

### Detail reports (regenerate in parallel)

| Workstream | Child page (overwrite this) | Parent plan (has generation prompt) |
| --- | --- | --- |
| TypeORM → Prisma Migration | `2e43d52b38384694b06f897645d82d3d` | `33c3c67199468023b997ef7e9821532b` |
| Vulnerability Remediation | `9c4798e8630e45ddb04aef74f661f4e1` | `33d3c671994681bd9c06ec8eaf76b95e` |
| Manage FE forms — Phase 1–2 (yum-ui / Formik decouple, prep work) | `d9a13af6e5274d8fb7c2e53e6a2fd7be` | `3403c6719946812ebd2fccd24545f931` |
| Manage FE forms — Phase 3–4 (Formik→RHF + Yup→Zod migration) | `547e626d2c4f4c48a0c77d96da682098` | `33d3c671994680d4b8bcfc716a88314a` |

**Note on the two Manage FE forms pages**: these two children cover different phases of the same Linear project (`2026 AI-pril Clean Kitchen - 🔪 Formik + Yup`), split by milestone. Phase 1–2 is the in-flight prep/decouple work (roughly 111 tickets). Phase 3–4 is the actual Formik→RHF and Yup→Zod migration (roughly 180 tickets, all in Backlog at time of writing, at risk of missing the Apr 30 deadline). Each parent plan's Generation prompt scopes the subagent's Linear query to the correct milestones: do not let a subagent lump them together.

### Consolidated snapshot (regenerate after all 4 above)

| Page | Child | Parent |
| --- | --- | --- |
| Clean Kitchen Project Snapshot | `f21bdc6b50be445b88cc3adb1ad30219` | `33a3c6719946818f8b3de7efaeb0a587` |

## Workflow

1. **Determine report date** (see section above).
2. **Create tasks** for the 5 pages via TaskCreate. Mark task 5 (consolidated) as `blockedBy` tasks 1–4.
3. **Dispatch 4 subagents in parallel** using a single message with four `Agent` tool calls, `subagent_type: "general-purpose"`, `run_in_background: true`. Use the subagent prompt template in the "Detail subagent prompt template" section below. Do not serialize.
4. **Wait for all 4 completion notifications.** Do not poll. Each subagent returns a short report with counts, deltas, and surprises.
5. **Aggregate the 4 subagent reports into a single data bundle** (done in the orchestrator's own context, not a subagent). This bundle drives the consolidated page.
6. **Dispatch the consolidated subagent** with the aggregated data using the template in "Consolidated subagent prompt template" below.
7. **Summarise to the user**: per-workstream health color, key number, anything noteworthy (tickets that shipped on the report date, scope corrections vs the previous day's page, anything that needs their attention).

## Sprint math

The parent plans reference a fixed sprint. As of writing: Apr 6 (Mon) to Apr 30 (Thu), 19 working days. But this will change between sprints. **Always read sprint start and deadline dates from the current detail child page before computing elapsed/remaining.** Do not hardcode.

Working-day math:
- Weekdays only, no public-holiday handling (none fall in the current sprint window).
- `elapsed` = working days from sprint start through and including the report date.
- `remaining` = working days strictly after the report date up to and including the deadline.
- `time_elapsed_pct` = `elapsed / (elapsed + remaining)` rounded to the nearest percent.

## Detail subagent prompt template

Pass each subagent a self-contained brief. They do not see the orchestrator's context. Replace the `{{ placeholders }}`.

```
You are regenerating a Notion daily progress report. {{ reason_clause }}

## Context
- Today is {{ today_date }}. Report date is **{{ report_date }}** ({{ report_weekday }}).
- Sprint window and total working days are recorded on the child page; read them from there.
- Working days elapsed = {{ elapsed }}, remaining = {{ remaining }}, time elapsed ≈ {{ time_elapsed_pct }}%.
- The page has a callout: "This page is overwritten daily. Previous entries are available via Page history." Overwriting is intended.

## Your task
1. Fetch the parent plan page: `https://www.notion.so/{{ parent_id }}` ({{ parent_title }}).
   Find the "Generation prompt" section (a toggle under a "## Progress updates" heading with a blockquote). It names the Linear project to query.
2. Fetch the current child page: `https://www.notion.so/{{ child_id }}` ({{ child_title }}).
   Study the existing tables, toggles, and assessment callout. You will preserve this format exactly. Only values, dates, and narrative change.
   **Scope-change exception**: if the parent plan's Generation prompt narrows or widens the milestone scope compared to the current child page (e.g. the prompt says "this page now covers Phase 3–4 only" but the existing page shows Phase 1–2 data), the parent prompt wins: rescope the tables to match the parent prompt and flag this in your report back. Do not preserve stale scoping.
3. Query Linear for ALL CUSM tickets in the project named in the generation prompt. Use `mcp__claude_ai_Linear__list_issues` with the `project` parameter. Paginate with `cursor` if needed. Capture identifier, title, state name, state type, assignee, completedAt, updatedAt.
4. Cross-reference Linear results with the parent plan page's listed tickets. The parent plan is authoritative for scope. Do NOT reduce the tracked ticket count below what the parent plan lists. If Linear has more tickets than the parent plan lists, include them all.
5. Regenerate the child page content for {{ report_date }}:
   - Title: "{{ child_title_without_date }} {{ report_date }}"
   - Metrics table: update elapsed/remaining/time elapsed.
   - Phase/Status tables: recompute from Linear current state.
   - Ticket detail toggles: update each ticket's status, completedAt, and any Apr-specific annotations. Use `<mention-date start="YYYY-MM-DD"/>` tags.
   - Velocity & projection: recompute. Velocity = cumulative_done / elapsed. Required = remaining_active / remaining. Projection = remaining_active / relevant_velocity.
   - Assessment callout: short, honest narrative of what moved on the report date. If nothing shipped, say so cleanly. Do not invent progress.
6. Overwrite the page:
   - Call `mcp__claude_ai_Notion__notion-update-page` with `command: "update_properties"` and `properties: { "title": "…" }`.
   - Then call `mcp__claude_ai_Notion__notion-update-page` with `command: "replace_content"` and `new_str` set to the full Notion-flavored Markdown body.

## Style rules
- No em dashes in new prose. Use commas, colons, or parentheses. Keep em dashes only in established titles/format elements (e.g. "TypeORM → Prisma Migration — Progress Update YYYY-MM-DD"); do not strip them there.
- Dates: Notion `<mention-date start="YYYY-MM-DD"/>` tags.
- Linear refs: CUSM-xxx inline, no URLs, unless the existing page format uses links (some parent plans do; match the child page's existing format).

## Report back (under 300 words)
- Page ID you updated.
- Total Linear tickets found in the project vs total tracked on the previous day's page.
- Phase/status count deltas vs the previous day's page.
- Tickets that closed on {{ report_date }} (list them).
- Any scope corrections (tickets the previous page missed, canceled items reclassified, etc.).
- Any surprises or data-quality issues worth escalating.
```

Use `{{ reason_clause }}` like "The user is running the daily report manually this morning" when the user invoked the skill, or "Yesterday's cron run was corrupted; the user is manually re-running it today" when relevant.

## Consolidated subagent prompt template

Only dispatch this after all 4 detail subagents have completed. Their reports provide the numbers you inject into `{{ typeorm_summary }}`, `{{ vuln_summary }}`, `{{ form_summary }}`.

```
You are regenerating the consolidated Clean Kitchen daily project snapshot in Notion. Four sibling detail reports were just updated for {{ report_date }}; your job is to aggregate them into the top-level snapshot.

## Context
- Today is {{ today_date }}. Report date is **{{ report_date }}** ({{ report_weekday }}).
- Sprint metrics: elapsed = {{ elapsed }}, remaining = {{ remaining }}, time elapsed ≈ {{ time_elapsed_pct }}%.
- The page has a callout: "This page is overwritten daily." Overwriting is intended.

## Your task
1. Fetch the parent page: `https://www.notion.so/33a3c6719946818f8b3de7efaeb0a587` ("Clean Kitchen: Unblock Manage Updates"). Find its "Generation prompt" section.
2. Fetch the current consolidated snapshot child page: `https://www.notion.so/f21bdc6b50be445b88cc3adb1ad30219`. Study its exact format:
   - Reporting-date callout
   - Overall Health table (Sub-project / Health / % Complete / Projected finish)
   - One section per workstream: metrics table + "Movement since last report" bullets + Assessment
   - Working-Days Schedule table
   - Recommendations numbered list
   Preserve this format exactly. If the parent's generation prompt describes a different structure, prefer the current page's structure (it is the user-approved format) and flag the divergence in your report.
3. Use the aggregated data below from the four detail subagents:

### TypeORM → Prisma Migration (child: `2e43d52b38384694b06f897645d82d3d`)
{{ typeorm_summary }}

### Vulnerability Remediation (child: `9c4798e8630e45ddb04aef74f661f4e1`)
{{ vuln_summary }}

### Manage FE forms (single consolidated workstream, two phases tracked as separate detail pages)

The two form-related detail pages cover different phases of the same underlying Linear project:
- **Phase 1–2 prep / decouple** (child `d9a13af6e5274d8fb7c2e53e6a2fd7be`): in-flight, roughly 111 tickets.
- **Phase 3–4 Formik→RHF + Yup→Zod** (child `547e626d2c4f4c48a0c77d96da682098`): not started, roughly 180 tickets, at risk of missing Apr 30.

In the Overall Health table, combine these into a **single "Manage FE forms" row** rather than two rows. That row's values:
- `% Complete` = done_across_all_4_phases / total_across_all_4_phases
- `Projected finish`: use the Phase 3–4 outlook, since the workstream as a whole cannot finish until Phase 3–4 completes.
- `Health` color: reflect the worse of the two (Phase 3–4 is at risk / red).
- Link to both child detail pages via `<mention-page url="…"/>` in the row's label or a note below.

For the per-workstream section below the Overall Health table, write one "Manage FE forms" section whose "Movement since last report" bullets and Assessment paragraph distinguish the two phases (e.g. "Phase 1–2: X tickets shipped today; Phase 3–4: not started, blocked on Phase 1–2").

Aggregated summary data (both phases):
{{ form_summary }}

4. Regenerate the consolidated page content for {{ report_date }}:
   - Title: "Clean Kitchen — Project Snapshot {{ report_date }}"
   - Reporting-date callout: {{ report_date }}, elapsed {{ elapsed }}/{{ total_working_days }} ({{ time_elapsed_pct }}%), remaining {{ remaining }}.
   - Overall Health table: one row per sub-project with the health color, % complete, projected finish.
   - Per-workstream sections: metrics + "Movement since last report" bullets + Assessment paragraph.
   - Working-Days Schedule table: list remaining working days from the day after {{ report_date }} up to the deadline. Remove any rows that are now in the past.
   - Recommendations: replace with guidance specific to the {{ report_date }} picture.
5. Overwrite:
   - `update_properties` with new title.
   - `replace_content` with full body.

## Style rules
- No em dashes in new prose. Keep them in titles/headings that already use them.
- Dates: Notion `<mention-date start="YYYY-MM-DD"/>` tags.
- `<mention-page url="…"/>` tags for cross-links to detail pages.

## Report back (under 200 words)
- Page ID updated.
- One-line summary of each workstream's health color and key number.
- If the parent's generation prompt differs from the current page structure, what you did and why.
```

## Guardrails

- **Never reduce the tracked ticket count below the parent plan's scope.** The user's standing complaint is that the prior notion-agent runs silently dropped tickets from the reports. If Linear is missing tickets the parent plan lists, flag it in the subagent report and surface those gaps to the user; do not quietly drop them.
- **Do not invent progress.** If nothing shipped on the report date, the assessment paragraph should say so in one sentence. Do not fabricate movement to fill the bullet list.
- **Style: no em dashes in new prose.** Preserve existing em dashes in titles, section headings, and table labels that already use them as format.
- **Always read sprint dates from the current page** rather than hardcoding. The sprint window will change over time.
- **Every subagent dispatch must include `run_in_background: true`** so the orchestrator doesn't block on each one.

## Final summary to the user

After the consolidated page updates, report back with:
- Report date used and why (explicit user input, time-of-day rule, or user choice if in the 9am–noon window).
- One line per workstream with the new health color and key number.
- Anything that shipped on the report date worth celebrating or flagging.
- Any scope corrections the subagents made to the previous day's page.
- Anything that needs the user's attention (review queues stuck, parent prompts drifting from the current page format, tickets in the parent plan not found in Linear, etc.).
