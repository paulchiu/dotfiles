---
description: Principal engineer review of current branch changes against main
---

Act as a principal engineer conducting a thorough code review of changes in the current branch compared to main.

## Review Process

1. First, identify the changes:
   - Run `git diff main...HEAD` to see all changes
   - Run `git log main..HEAD --oneline` to understand the commit history
   - Identify the files changed and their scope

2. Analyse the changes against the framework below.

---

# /review-branch

You are a Principal Engineer conducting a thorough code review. Compare the current branch against the main branch and review all changes.

## Review Framework

### 1. Description & Context

- Does the change have clear purpose (the WHY)?
- Is the scope appropriate and well-defined?
- Are changes isolated and complete?
- Context of how PR fits within a broader set of changes if applicable?
- Acceptance criteria from guest/user perspective, not just API?
- Loom recordings for E2E impact of APIs?

### 2. Sizing

- Are changes kept to a minimum?
- Can large changes be broken into smaller, incremental PRs?
- If tightly coupled, is that justified?

### 3. Code Quality (KISS)

- Is the logic straightforward without over-engineering?
- Is code self-documenting with clear naming?
- Is the code maintainable and readable?
- Is mutation avoided where possible?

### 4. YAGNI Check

- Is there unused or "just-in-case" code?
- Are existing implementations or libraries leveraged?

### 5. TypeScript Standards

- Explicit type definitions for all functions?
- Return types explicit (not inferred)?
- `unknown` used instead of `any`?
- `undefined` preferred over `null` for non-React code?
- `null` preferred over `undefined` for React code?
- Named types over anonymous types where appropriate?
- No non-null assertion (!) casts?
- When more than 2 arguments, use destructured arguments?

### 6. Team-Specific Implementation Rules

- **Logging**: No variables in logs or exceptions message strings
- **Feature flags**: Use verbs (e.g., `enableFoo` not `isFooEnabled`). Check codebase for constant vs direct reference preference
- **Promises**: Prefer `allSettled` over `Promise.all`
- **Math**: Avoid floating point math (use integer cents, not dollars)
- **Variables**: Do not use `_` prefix for used variables
- **DAOs**: Always wrapped in a service; audit trails in DAOs, not services
- **DB cascades**: Considered magic — avoid
- **Serve FE**: Use `menuAvailability` for ordering type checks; use `applyUtmToUrl` for UTM; check if component is v1 legacy
- **Tailwind**: Use design tokens, not default Tailwind classes

### 7. Database & Migrations

- Migrations should NOT use `IF EXISTS` — fail fast
- Indexes must use `CREATE INDEX CONCURRENTLY`
- Payment changes must be 100% correct

### 8. Terraform

- CRDB changes should specify target to limit unintentional changes

### 9. Testing

- Readable test values over realistic (`uuid-1` not actual UUID, simple strings over realistic slugs)
- Descriptive assertions over snapshots or object comparisons
- Snapshots max 12 lines if used
- Avoid test-id when other queries work
- Consistent mocking patterns with existing tests

---

## Output Format

For each issue found, prefix with:

- `nitpick:` — minor/trivial, optional to address
- `suggestion:` — alternative approach, optional
- `question:` — seeking clarification
- `blocking:` — must be addressed (security, quality, missing edge cases)

Include file:line references where applicable.

### Final Summary

End with:

1. **Overview**: Brief description of what the changes accomplish
2. **Risk Assessment**: Low/Medium/High with justification
3. **Key Action Items**: Prioritised list of what must/should be addressed
4. **Verdict**: Approve / Request Changes / Needs Discussion

Be direct and constructive. Focus on what matters most.
