---
name: check-agent-standards
description: "Checks current branch changes against local main for AGENTS.md conformance, writes a report, and auto-fixes violations. Use when asked to enforce standards, check conformance, or fix branch to match AGENTS.md."
---

# Check Agent Standards

Automatically audit the current branch's changes against `AGENTS.md` project standards, write a report, and fix all violations without intervention.

## Prerequisites

- Must be in a git repository with a local `main` branch
- Must have an `AGENTS.md` file in the project root

## Workflow

### Step 1: Gather Context

1. Read `AGENTS.md` from the project root to understand all project standards.
2. Run `git diff main...HEAD --name-only` to list changed files.
3. Run `git diff main...HEAD` to get the full diff.
4. Run `git log main..HEAD --oneline` to understand commit history.
5. If no changes are found, report "No changes detected" and stop.

### Step 2: Audit Changes

Check every changed file against all applicable rules from `AGENTS.md`. The audit must cover every section of `AGENTS.md` that applies to the changed files. Common checks include (but are not limited to — always derive checks from the actual `AGENTS.md`):

**File & Naming Conventions:**
- File naming matches conventions (PascalCase for components, camelCase for hooks/utils)
- Files are in the correct directories per architecture rules
- Test files are colocated with source

**Code Standards:**
- Formatting matches Prettier config (semi, quotes, trailing commas, print width, tab width)
- No `any` types — `unknown` with narrowing instead
- Props interfaces defined above components with `Props` suffix
- Type-only imports use `import type { ... }`
- Explicit return types on all exported functions
- JSDoc with `@param` and `@returns` on all exported functions and hooks
- No class components
- No `console.log`
- No React namespace imports (`import React from 'react'`)
- Immutability — `const` by default, no mutation

**Architecture:**
- Pure functions extracted to `/utils` where possible
- State management follows hierarchy: URL params > Context > global store
- Path aliases use `@/*`

**Testing:**
- Changed util functions have corresponding test files
- Tests use `describe` blocks with descriptive `it` names (lowercase verbs)
- Pure functions have edge case and error handling coverage

**Error Handling:**
- Recoverable errors return `null`
- User feedback via callbacks or toasts, no silent swallowing

### Step 3: Write Report

Write a markdown report to `CONFORMANCE_REPORT.md` in the project root with the following structure:

```markdown
# Conformance Report

**Branch:** `<branch-name>`
**Date:** `<date>`
**Compared against:** `local main`
**Standards:** `AGENTS.md`

## Summary

- **Files changed:** <count>
- **Violations found:** <count>
- **Auto-fixable:** <count>
- **Manual review needed:** <count>

## Violations

### <filename>

| # | Rule | Severity | Description | Auto-fix |
|---|------|----------|-------------|----------|
| 1 | <AGENTS.md section> | error/warning | <description> | ✅/❌ |

## Actions Taken

- [ ] <description of each fix applied>

## Remaining Items

- [ ] <items requiring manual intervention, if any>
```

### Step 4: Auto-Fix Violations

Fix all violations that can be safely auto-fixed:

1. **Formatting:** Run the project formatter (e.g., `npm run format`) if available.
2. **Linting:** Run the project linter with auto-fix (e.g., `npm run lint -- --fix`) if available.
3. **Missing return types:** Add explicit return types to exported functions.
4. **Missing JSDoc:** Add JSDoc stubs with `@param` and `@returns`.
5. **Type imports:** Convert type-only imports to `import type { ... }`.
6. **`any` types:** Replace with `unknown` where safe (flag complex cases for manual review).
7. **`console.log`:** Remove from non-test files.
8. **React namespace imports:** Convert to named imports.
9. **Missing tests:** Create test file stubs for new utility functions.

After fixes, re-run linting and tests to verify nothing is broken:
- Run `npm run lint` (must pass with zero warnings)
- Run `npm test` (must pass)

### Step 5: Update Report

Update `CONFORMANCE_REPORT.md` to reflect which fixes were applied and which items remain.

## Important Rules

- **Never leave the codebase broken.** If a fix causes lint or test failures, revert it and mark as manual review.
- **Do not modify test expectations** to make tests pass — fix the source code instead.
- **Do not touch files outside the branch diff** unless running project-wide formatters.
- **Be conservative with type changes** — prefer flagging complex `any` replacements for manual review over introducing type errors.
- Add `CONFORMANCE_REPORT.md` to `.gitignore` if it is not already there — it is a transient artifact.
