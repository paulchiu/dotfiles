---
name: reviewing-branch-changes
description: Principal engineer review of current branch changes against main. Use when asked to review branch, review changes, review a PR, or do a code review of the current branch. Produce a checklist-first review with stable finding IDs plus GitHub-ready, file-by-file review comments with exact line targets, severity, practical fix guidance, and high-signal reasoning.
---

# Branch Review Skill

Perform a strict principal-engineer review of the current branch versus `main`, with output shaped like real GitHub PR comments.

Treat this file as the execution contract. Use references for detailed policy.

## Load Guidance Sources

Read in this order before reviewing:

1. `references/team-pr-references.md`
2. `references/pull-request-review-guidelines.md`
3. `references/other-team-pr-preferences.md`

Use bundled references only.

## Core Behavior

- Lead with actionable comments, not summary text.
- Primary output is checklist-first, followed by file-by-file review comments.
- Prefer fewer, high-confidence comments over noisy low-confidence comments.
- Treat convention and standards violations as valid findings.
- Do not waive findings because similar legacy patterns exist.
- Include exact review targets (`file:line`) for each comment.
- Use `blocking` only when merge should not proceed without the fix.
- Always present a checklist of actionable findings with stable finding IDs before detailed review comments.
- When the user asks for selected findings to be rewritten for posting, preserve the substance of the finding but follow the requested wrapper format exactly.

## GPT-5.3 Reasoning

Use this internal loop for each potential finding:

1. Evidence: exact changed lines and observed behavior.
2. Rule: concrete team convention, policy, or official docs.
3. Impact: realistic risk (correctness, security, reliability, maintainability).
4. Fix: smallest practical correction.

False-positive gate:

- Is this in changed code or directly impacted code?
- Is there a clear standard behind the comment?
- Is severity aligned with impact and confidence?
- Can the author act without guessing?

If confidence is low, prefer `question` over `blocking` or `suggestion`.

## Severity

- `blocking`: correctness, security, data integrity, payment safety, or must-fix standards issue.
- `suggestion`: meaningful non-blocking improvement.
- `question`: clarification request or low-confidence concern.
- `nitpick`: minor polish with negligible impact.

Escalate only when both impact and confidence are high.

## Review Flow

1. Scope changes:
   - `git diff main...HEAD`
   - `git log main..HEAD --oneline`
   - `git diff --name-only main...HEAD`
2. Run targeted scans on changed files:
   - Prefer `rg` (`useFlag`, `Promise.all`, `any`, non-null assertions, logging patterns, etc.)
   - Run lint/type checks when available for touched paths.
3. Gather link context:
   - `git rev-parse --abbrev-ref HEAD`
   - `git rev-parse HEAD`
   - `git remote get-url origin`
4. Build a risk map:
   - Mark security, payment, migration, infra, and user-visible behavior as high attention.
   - Treat payment changes as high-risk and require very high confidence.
5. Validate tests:
   - Confirm tests cover behavioral changes.
   - If tests are missing, require explicit justification.
6. Produce output in the required format below.

## What To Check (Condensed)

Use references for full details. Always evaluate:

- PR context: WHY, scope, stakeholder/user impact, sizing, and coupling clarity.
- Code quality: KISS, maintainability, naming clarity, mutation minimization, YAGNI.
- TypeScript: avoid `any`, null/undefined conventions, non-null assertions, argument structure.
- Team conventions: logging strings, feature flag style, Promise handling, money math, DAO patterns, FE-specific conventions, Tailwind tokens.
- Data and infra: migration safety (`IF EXISTS`, index strategy), CRDB/Terraform scoping.
- Tests: coverage quality, readable fixtures, strong assertions, snapshot restraint, query quality.

## Required Output Format

Output in this order:

1. **Checklist** (required, primary)
2. **File-by-File Review Comments** (required)
3. **Cross-File Comments** (optional)
4. **Open Questions / Assumptions**
5. **Risk Assessment**: Low / Medium / High with justification
6. **Verdict**: Approve / Request Changes / Needs Discussion

## Required Checklist Mode

Include this in every main review output:

- Output a flat checklist before the full review comments.
- Assign each actionable finding a stable short ID such as `DT-1`, `PAY-1`, `ORD-1`.
- Prefer mnemonic prefixes derived from the file or domain.
- Keep each checklist item to one line with:
  - checkbox marker
  - finding ID
  - clickable file reference
  - one-sentence issue summary
- Do not include non-findings in the checklist.
- Preserve finding order by severity, then file diff order, then line number.

If there are no actionable findings, output `No findings.` in the checklist section.

Template:

```md
- [ ] `DT-1` [path/to/file.ts](/abs/path/to/file.ts#L42): Short issue summary.
```

## Optional GitHub Draft Mode

When the user names a subset of checklist IDs and asks for drafts to reply with or post:

- Return only the requested findings.
- If the user supplies their own note text, include it as `My note:` before the generated `LLM note:`.
- If the user does not supply their own note text, omit the `My note:` line.
- Use this exact wrapper:

````md
My note: <user-supplied note>

LLM note: <short version>

<details>
  <summary>LLM reasoning</summary>

<clear issue statement and impact, written as a plain opening paragraph with no severity label>

Why this matters: 1-3 sentences on concrete impact.

Recommended change
```ts
// minimal fix sketch or exact replacement
```

References (optional)
- [Changed line link](https://github.com/<org>/<repo>/blob/<head-sha>/path/to/file.ts#L<line>)
- [Comparison/convention link](https://github.com/<org>/<repo>/blob/<sha>/path/to/file.ts#L<line>)
- [Official docs/spec link](https://...)

Current code (optional)
```ts
// 3-12 lines from changed code near the target line
```

Preferred code (optional)
```ts
// 3-12 lines showing the preferred pattern
```

Patch-style diff (optional)
```diff
- old line(s)
+ new line(s)
```
</details>
````

Rules for this mode:

- Do not use `Blocking:`, `Suggestion:`, `Question:`, or `Nitpick:` inside the `<details>` body unless the user explicitly asks for a labeled variant.
- Start the reasoning body immediately after the summary with a plain paragraph that states the issue and expected fix direction.
- Keep the short `LLM note:` line concise and non-redundant.
- Preserve the wrapper order exactly: optional `My note:`, then `LLM note:`, then `<details>`.
- Do not repeat the `LLM note:` wording verbatim in the first paragraph.
- Preserve the original reasoning, impact, and fix guidance from the review.
- Use the same wrapper and section ordering when drafting text for direct GitHub review comments unless the user explicitly asks for a different format.

## Posting With `gh`

When the user asks to leave selected feedback directly on GitHub, prefer an inline PR comment via `gh api`.

1. Resolve PR context:
   - `gh pr view --json number,url,headRefOid,headRefName,baseRefName`
   - Use `headRefOid` as `commit_id`.
2. Confirm the exact changed line in the file with `nl -ba` or `git diff --unified=...`.
   - If the issue is about behavior introduced by a refactor, extraction, or moved code, anchor the comment on a nearby changed line in the diff hunk that introduces that behavior. Do not target unchanged context lines that are outside the PR diff.
3. Post the comment with:
   - Prefer a temp Markdown file plus JSON payload over inline shell strings when the body contains backticks, quotes, or fenced code blocks.
   - Reliable pattern:
     - write the wrapper body to `/tmp/<name>.md`
     - serialize it with `node -e "const fs=require('fs'); const body=fs.readFileSync('/tmp/<name>.md','utf8'); fs.writeFileSync('/tmp/<name>.json', JSON.stringify({ body }));"`
     - `gh api repos/<org>/<repo>/pulls/<pr-number>/comments -X POST -f commit_id=<head-sha> -f path=<repo-path> -F line=<line> -f side=RIGHT --input /tmp/<name>.json`
   - Avoid inline `$'...'` bodies for Markdown-heavy comments; shell quoting can silently strip content such as backticks or `''` in code samples.
4. Use the GitHub draft wrapper above as the comment body unless the user explicitly asked for a different format.
5. Inspect the API response after posting:
   - capture `html_url` for reporting back
   - sanity-check the returned `body` to make sure fenced code and quotes were preserved
   - if GitHub received a mangled body, patch the existing comment with `gh api repos/<org>/<repo>/pulls/comments/<comment-id> -X PATCH --input /tmp/<name>.json`
6. After posting, report the PR URL or discussion URL back to the user.

Notes:

- Prefer `pulls/<pr-number>/comments` for inline file comments, not general PR discussion comments.
- The target line must exist in the PR diff hunk; use the changed-side line number.
- Networked `gh` calls may require escalated permissions in Codex. When requesting escalation, set a `prefix_rule` scoped to the relevant `gh api repos/<org>/<repo>/pulls` path when possible.

### 1) Checklist

List every actionable finding once, in checklist form, before the detailed review comments.

### 2) File-by-File Review Comments

Get changed files in diff order (`git diff --name-only main...HEAD`) and count them (`N`).

- If `N < 20`: list every changed file.
- If `N >= 20`: list only files with actionable comments.
- For `N >= 20`, add: `Reviewed <N> changed files; comments on <M> files.`

For each file:

- Heading: `### path/to/file.ext`
- If none: `No comments for this file.`
- If comments exist, include for each:
  - `Line <line-number>` or `Line <start>-<end>`
  - severity (`blocking`, `suggestion`, `question`, `nitpick`)
  - full comment body using template below.

Within each file, order comments by:

1. severity (`blocking`, `suggestion`, `question`, `nitpick`)
2. line number ascending

### 3) Cross-File Comments

Only for inherently cross-cutting concerns (architecture, rollout safety, migration strategy, e2e risks).

### 4) No-Issue Case

If there are no actionable comments across all changed files, explicitly output:

`No findings.`

Still include:

- Checklist
- Open Questions / Assumptions
- Risk Assessment
- Verdict

## PR Comment Template

````md
<Severity>: <clear issue statement and impact>

Why this matters: 1-3 sentences on concrete impact.

Recommended change
```ts
// minimal fix sketch or exact replacement
```

References (optional)
- [Changed line link](https://github.com/<org>/<repo>/blob/<head-sha>/path/to/file.ts#L<line>)
- [Comparison/convention link](https://github.com/<org>/<repo>/blob/<sha>/path/to/file.ts#L<line>)
- [Official docs/spec link](https://...)

Current code (optional)
```ts
// 3-12 lines from changed code near the target line
```

Preferred code (optional)
```ts
// 3-12 lines showing the preferred pattern
```

Patch-style diff (optional)
```diff
- old line(s)
+ new line(s)
```
````

## Comment Quality Rules

- Keep comments self-contained and pasteable into GitHub.
- Include exact line targets in every finding using the file section and `Line <n>` metadata; do not add a separate `Comment target` line inside the comment body.
- Use label style `Suggestion:`, `Blocking:`, `Question:`, `Nitpick:` (capitalized, plain text, no bold formatting).
- Use references when they increase clarity; do not force for trivial nits.
- Include snippets for non-trivial issues; include current-vs-preferred for convention enforcement.
- Use plain markdown only (no HTML `<details>` / `<summary>`).
- Prefer concrete fix guidance over abstract advice.
- Do not output generic praise comments.
- Exception: in GitHub Draft Mode, the requested `<details>` wrapper is allowed and should be used verbatim.

Be direct and practical. Enforce standards while calibrating severity to real impact.
