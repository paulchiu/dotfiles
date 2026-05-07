# Implementation Guidance Formatting Guidelines

This document contains the complete formatting standards for generating implementation guidance documents.

## Document Structure

### Required Sections

Every implementation guidance document must include:

1. **Linear Issue Header** - Issue ID, title, and link to Linear
2. **Issue Metadata** - Status, priority, and other relevant Linear metadata
3. **Issue Description** - The full description from Linear (including relevant comments)
4. **Implementation guidance** - The main section with actionable steps
5. **File References** - Specific files that need modification
6. **Next Steps** - Clear action items for implementation

### Document Header Format

Always start with the Linear issue information:

```markdown
# [ISSUE-ID]: [Issue Title]

**Linear Issue:** [ISSUE-ID](https://linear.app/workspace/issue/ISSUE-ID)
**Status:** [Status] | **Priority:** [Priority]

## Issue Description

[Full description from Linear]
```

### Implementation Guidance Section Format

Always use the exact header: `## Implementation guidance`

Follow this structure for the content:

```markdown
## Implementation guidance

* The culprit for this is most likely `FunctionName.methodName` ([GitHub](https://github.com/[repo/path/file.ext]#L123)), which has the query:

```typescript
[Code example showing the problematic code]
```

* Alternative approach: modify `OtherService.method` ([GitHub](https://github.com/repo/path/other.ts#L42))
* [Additional context and implementation notes]
```

## Style Guidelines

### Content Structure Requirements

1. **Primary implementation approach** - Start with the most likely solution or entry point
2. **Specific code locations** - Include GitHub links with exact file paths and line numbers
3. **Code examples** - Show relevant code snippets when helpful
4. **Multiple approaches** - When applicable, show alternative solutions (labeled as "attempt 1", "attempt 2", etc.)
5. **Context and constraints** - Include relevant technical constraints or considerations

### Formatting Rules

- Use bullet points for clear, actionable steps
- Include GitHub links in this format: `([GitHub](https://github.com/[repo/path/file.ext]#L123))`
- Reference specific functions, classes, and variables with backticks: `FunctionName.methodName`
- When showing code, use proper TypeScript syntax highlighting
- Be specific about file locations and line numbers
- Include explanatory context for why certain approaches are recommended
- When multiple attempts are shown, clearly label them and explain the reasoning

## File Naming Convention

Use this pattern for all implementation guidance documents:
```
yyyy-mm-dd [ISSUE-ID] [short description].md
```

### Examples
- `2025-10-24 PROJ-123 Database migration strategy.md`
- `2025-10-24 PERF-456 Performance optimization plan.md`
- `2025-10-24 BUG-789 Fix authentication bug.md`

### Guidelines
- Use ISO date format yyyy-mm-dd
- Include the Linear issue ID immediately after the date (e.g., PROJ-123)
- Do not put square brackets around the date or issue ID
- Keep descriptions concise (based on Linear issue title)
- Use sentence case for descriptions, headings, and filenames
- Include file extension `.md`
- Use spaces for multi-word descriptions

## Content Organization

### Document Structure
- Clear hierarchy using standard markdown headings (H1, H2, H3, etc.)
- Code blocks with appropriate language highlighting
- Checklists for actionable items
- Internal links using `[[filename]]` format for related documents

### Writing Style
- Keep it concise, write for a senior software engineer audience
- Use imperative/infinitive form (verb-first instructions)
- Use objective, instructional language
- "To accomplish X, do Y" instead of "You should do X"

## GitHub Link Format

### Standard Format
```
([GitHub](https://github.com/[username]/[repository]/blob/[branch]/[path/to/file.ext]#L123))
```

### Examples
```markdown
* Check the authentication logic in `UserService.authenticate` ([GitHub](https://github.com/company/project/blob/main/src/services/UserService.ts#L45))
* The database query is in `OrderRepository.findOrders` ([GitHub](https://github.com/company/project/blob/main/src/repositories/OrderRepository.js#L78))
```

## Code Examples

### TypeScript/JavaScript
```typescript
// Highlight problematic code
const result = await this.service.findUser(id);
if (!result) {
  throw new Error('User not found');
}
```

### Python
```python
# Show the issue
def calculate_total(items):
    total = 0
    for item in items:
        total += item.price  # Missing null check
    return total
```

## Context and Constraints

Always include relevant technical considerations:
- Performance implications
- Security considerations
- Breaking changes
- Dependencies that might be affected
- Testing requirements