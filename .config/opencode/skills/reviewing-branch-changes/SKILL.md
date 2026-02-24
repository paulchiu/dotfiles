---
name: reviewing-branch-changes
description: Principal engineer review of current branch changes against main. Use when asked to review branch, review changes, or do a code review of the current branch.
---

# Branch Review Skill

Perform a strict principal-engineer review of changes in the current branch compared to `main`.

Treat the guidance below as required PR review behavior, not optional suggestions.

## Non-Negotiables

- Lead with findings, ordered by severity.
- Treat standards and convention violations as real findings even if runtime behavior still works.
- Run a dedicated pass for team-specific rules, especially feature flag naming.
- Do not waive findings because similar legacy patterns already exist.
- Use concrete `file:line` references for every finding.

## Review Process

1. Identify change scope:
   - Run `git diff main...HEAD`
   - Run `git log main..HEAD --oneline`
   - Run `git diff --name-only main...HEAD`

2. Run focused static checks on changed files:
   - Prefer `rg` for targeted scans (`useFlag`, `Promise.all`, `any`, non-null assertions, logging patterns, etc.)
   - Run lint/type checks for changed files when available (for example `npm run check:linting -- <files...>`)

3. Review against the framework below.

4. Verify test coverage for behavioral changes:
   - Confirm existing tests cover changed paths, or flag missing tests.

5. Produce findings-first output in the required format.

## Review Framework

### 1. Description & Context

- Is the change purpose clear (the WHY)?
- Is scope well-defined and complete?
- Does the PR capture guest/user impact, not just API impact?

### 2. Sizing

- Is change size reasonable?
- Should coupled work be split into smaller PRs?

### 3. Code Quality (KISS)

- Is logic straightforward and maintainable?
- Are naming and abstractions clear?
- Is unnecessary mutation avoided?

### 4. YAGNI

- Is any code speculative or unused?
- Are existing utilities/libraries reused where appropriate?

### 5. TypeScript Standards

- Use explicit types where team conventions require it.
- Prefer `unknown` over `any`.
- Prefer `undefined` over `null` for non-React code.
- Prefer `null` over `undefined` for React code.
- Avoid non-null assertions (`!`) unless clearly justified.
- When more than 2 arguments are passed, prefer destructured arguments.

### 6. Team-Specific Implementation Rules

- Logging: do not interpolate variables in log/exception message strings.
- Feature flags:
  - Use verb-style variable names for flags in code (for example `enableOtpRateLimit`).
  - Flag names like `FLAG_ENABLE_*` are fine for constants.
  - Do not use `isFooEnabled` for newly introduced flag booleans.
  - Always call this out when feature-flag code is touched.
- Promises: prefer `Promise.allSettled` over `Promise.all`.
- Math: avoid floating point money math; use integer cents.
- Variables: do not use `_` prefix for used variables.
- DAOs: keep DAOs wrapped in services; keep audit trails in DAOs.
- DB cascades: avoid implicit cascade behavior.
- Serve FE specifics:
  - Use `menuAvailability` for ordering type checks.
  - Use `applyUtmToUrl` for UTM application.
  - Check whether touched component is legacy v1 before introducing new patterns.
- Tailwind: use design tokens, not default Tailwind classes.

### 7. Database & Migrations

- Do not use `IF EXISTS` in migrations.
- Use `CREATE INDEX CONCURRENTLY` for indexes.
- Treat payment changes as high-risk and require high confidence.

### 8. Terraform

- For CRDB changes, require explicit target scoping.

### 9. Testing

- Prefer readable fixture values over overly realistic values.
- Prefer descriptive assertions over broad snapshots/object dumps.
- Keep snapshots short (max ~12 lines) if used.
- Avoid `test-id` where better queries exist.
- Keep mocking style consistent with nearby tests.

## Required Output Format

Output findings first, in this order:

1. `blocking:`
2. `suggestion:`
3. `question:`
4. `nitpick:`

For every finding:

- Start with `<severity>: <issue and impact>`
- Add `References:` with concrete `path/to/file.ts:123`
- Prefer line-specific GitHub links when available
- Add a short snippet (3-12 lines) for key findings
- Add a convention comparison snippet when arguing convention mismatch

If there are no findings, explicitly say: `No findings.`

Then include:

1. **Open Questions / Assumptions**
2. **Overview**
3. **Risk Assessment**: Low / Medium / High with justification
4. **Key Action Items**: prioritized
5. **Verdict**: Approve / Request Changes / Needs Discussion

## PR Comment Template

````md
<severity>: <clear issue statement and impact>

<details>
  <summary>References</summary>
  
- `path/to/changed-file.ts:123` ([GitHub](https://github.com/<org>/<repo>/blob/<branch>/path/to/changed-file.ts#L123))
- `path/to/convention-file.ts:45` ([GitHub](https://github.com/<org>/<repo>/blob/<branch>/path/to/convention-file.ts#L45))
</details>

<details>
  <summary>Sample snippets</summary>
  
Changed code snippet:
```ts
// 3-12 lines from changed code
```

Convention comparison snippet:
```ts
// 3-12 lines from existing codebase convention
```
</details>
````

Be direct, concrete, and strict about standards compliance.
