---
name: implementation-guidance-generator
description: "Generates Obsidian-style implementation guidance docs for technical issues, bug fixes, and features with file refs, code locations, and step-by-step plans. Trigger phrases: 'implementation guidance', 'guidance doc', 'write up how to fix', or turning a Linear issue into an Obsidian implementation doc."
---

# Implementation Guidance Generator

Turn a Linear issue into an Obsidian-ready implementation guidance doc: file refs, exact code locations, and a concrete plan.

## Workflow

1. Get the Linear issue URL from the user (ask if not provided), then fetch the full issue via the Linear MCP get-issue tool: title, description, status, priority, labels, and comments.
2. Investigate the codebase to identify the affected files, functions, and line numbers, plus dependencies the change might touch. Note alternative approaches where they exist.
3. Write the doc using the template below. For complete formatting standards (writing style, code example conventions, multi-attempt labeling), read [formatting_guidelines.md](references/formatting_guidelines.md).

## Document Template

````markdown
# [ISSUE-ID]: [Issue Title]

**Linear Issue:** [ISSUE-ID](https://linear.app/workspace/issue/ISSUE-ID)
**Status:** [Status] | **Priority:** [Priority]

## Issue Description

[Full description from Linear, including relevant context from comments]

## Implementation guidance

* The culprit for this is most likely `FunctionName.methodName` ([GitHub](https://github.com/org/repo/blob/main/path/file.ts#L123)), which has the query:

```typescript
[problematic code]
```

* Alternative approach: modify `OtherService.method` ([GitHub](https://github.com/org/repo/blob/main/path/other.ts#L42))
* [Additional context: constraints, performance/security implications, breaking changes, testing notes]
````

Hard rules:

- The main section header is exactly `## Implementation guidance`.
- Every code location gets a GitHub link with exact path and line number: `([GitHub](https://github.com/org/repo/blob/branch/path/file.ext#L123))`.
- Backtick function/class references, bulleted actionable steps, imperative prose for a senior-engineer audience.
- Internal links to related docs use Obsidian `[[filename]]` format.

## File Naming

`yyyy-mm-dd [ISSUE-ID] [short description].md`, e.g. `2025-10-24 PROJ-123 Fix authentication bug.md`. ISO date, no brackets around date or ID, sentence-case description based on the issue title.

## Resources

- `references/formatting_guidelines.md`: complete formatting and style standards.
- `scripts/generate_guidance.py`: legacy reference only; generate docs directly via the workflow above.
