---
name: reviewing-branch-changes
description: Principal engineer review of current branch changes against main. Use when asked to review branch, review changes, review a PR, or do a code review of the current branch. Produce GitHub-ready, file-by-file review comments with exact line targets, severity, practical fix guidance, and high-signal reasoning.
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
- Primary output is file-by-file.
- Prefer fewer, high-confidence comments over noisy low-confidence comments.
- Treat convention and standards violations as valid findings.
- Do not waive findings because similar legacy patterns exist.
- Include exact review targets (`file:line`) for each comment.
- Use `blocking` only when merge should not proceed without the fix.

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

1. **File-by-File Review Comments** (required, primary)
2. **Cross-File Comments** (optional)
3. **Open Questions / Assumptions**
4. **Risk Assessment**: Low / Medium / High with justification
5. **Verdict**: Approve / Request Changes / Needs Discussion

### 1) File-by-File Review Comments

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

### 2) Cross-File Comments

Only for inherently cross-cutting concerns (architecture, rollout safety, migration strategy, e2e risks).

### 3) No-Issue Case

If there are no actionable comments across all changed files, explicitly output:

`No findings.`

Still include:

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

Be direct and practical. Enforce standards while calibrating severity to real impact.
