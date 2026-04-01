---
name: linear-rewrite
description: Rewrites Linear issues to match the team's structured template. Use when asked to rewrite, restructure, or improve a Linear issue, or when a Linear issue URL/ID is provided with intent to clean up its description.
---

# Linear Issue Rewrite

Rewrite a Linear issue's description to match the team's structured template. Preserves the original description and surfaces open questions for resolution.

## Workflow

1. **Parse input**: extract the Linear issue ID from the user's message (e.g., `CAD-1295` or a `linear.app` URL)
2. **Fetch the issue** using the `mcp__claude_ai_Linear__get_issue` tool
3. **Read the current description** carefully. Identify:
   - The core goal / problem statement
   - Any listed items, handlers, endpoints, or resources
   - Open questions from the original author
   - Any context about scope or exclusions
4. **Ask the user clarifying questions** before rewriting. Good questions include:
   - Scope boundaries (what's in, what's out)
   - Implementation details the template requires but the issue lacks
   - Answers to the original author's open questions
   - Whether sub-issues should be created and how to group them
   - Verification approach
   - Risk tier assessment
5. **Research codebases** if the user points you to them, to answer implementation guidance, file paths, and open questions
6. **Draft the rewrite** following the template below, and present a plan to the user before updating
7. **Update the issue** using `mcp__claude_ai_Linear__save_issue` with the rewritten description
8. **Create sub-issues** if requested, each following the same template and referencing the parent

## Issue Template

Every rewritten issue MUST follow this structure:

```markdown
## Summary
[One sentence: what this card accomplishes and why]

## Acceptance criteria
- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]

## Scope

### In scope
- [Specific change 1]

### Out of scope
- [Thing that might look related but must not be touched]

## Implementation guidance
- Follow pattern in: `[specific file path]`
- Use existing utility: `[specific import path]`
- When uncertain: [stop and explain ambiguity / propose a plan]

## Verification
[Exact commands or steps to verify the change works]

## Risk tier
[Low / Medium / High] -- [One sentence justification]

## Files likely involved
- `src/[module]/[file].ts`
```

## Preserving Original Content

When rewriting an existing issue:

- **Always** preserve the original description in a collapsed section at the bottom:

```markdown
<details>
<summary>Original description (pre-YYYY-MM-DD)</summary>

[original description verbatim]

</details>
```

- **Always** add a Q&A section if the original had open questions or if clarifying questions were answered during the rewrite:

```markdown
## Q&A

**Q (original author):** [question from original description]
**A:** [answer determined during rewrite]
```

## Sub-issue Creation

When creating sub-issues:

- Each sub-issue follows the same template
- Reference the parent issue in the description: `Parent issue: [TEAM-NUMBER]`
- Use the same team, project, and labels as the parent
- Group related items logically (by module, domain, or handler type)
- Set appropriate estimates based on the number of items in each sub-issue

## Guidelines

- Do NOT update the issue until the user approves the plan
- Ask questions up front rather than guessing at scope or implementation details
- If the user points to codebases, research them to fill in implementation guidance and file paths
- Keep acceptance criteria specific and testable
- Risk tier should reflect the actual change, not the importance of the feature
- When listing handlers/endpoints/items, prefer grouping by module or domain over listing individually
