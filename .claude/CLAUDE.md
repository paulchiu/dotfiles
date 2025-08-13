# Claude Code Instructions

This file contains project-specific instructions for Claude Code to follow when working in this codebase.

## Documentation and Planning Standards

### Obsidian Markdown Style
- Use **Obsidian markdown formatting** for all documentation and planning files
- Follow Obsidian conventions for internal linking with `[[filename]]`
- Structure content with clear hierarchy using standard markdown headings

### File Naming Convention
All planning documents, analyses, and documentation files should follow this naming pattern:
```
yyyy-mm-dd [short description].md
```

**Examples:**
- `2025-08-10 Database migration strategy.md`
- `2025-08-09 Performance optimization plan.md`

**Guidelines:**
- Use ISO date format yyyy-mm-dd
- Do not put square brackets around the date
- Keep descriptions concise
- Use sentence case for descriptions, headings, and filenames
- Include file extension `.md`
- Use spaces for multi-word descriptions

### Content Structure
When creating plans or documentation:
- Keep it concise, write for a senior software engineer audience
- Use hierarchical heading structure (H1, H2, H3, etc.)
- Use code blocks with appropriate language highlighting
- Include checklists for actionable items
- Add relevant internal links using `[[filename]]` format

## Implementation Guidance Standards

When writing implementation guidance for technical tasks, follow this specific structure and style:

### Section Header
Always use the exact header: `## Implementation guidance`

### Content Structure
1. **Primary implementation approach** - Start with the most likely solution or entry point
2. **Specific code locations** - Include GitHub links with exact file paths and line numbers
3. **Code examples** - Show relevant code snippets when helpful
4. **Multiple approaches** - When applicable, show alternative solutions (labeled as "attempt 1", "attempt 2", etc.)
5. **Context and constraints** - Include relevant technical constraints or considerations

### Style Guidelines
- Use bullet points for clear, actionable steps
- Include GitHub links in this format: `([GitHub](https://github.com/repo/path/file.ext#L123))`
- Reference specific functions, classes, and variables with backticks: `FunctionName.methodName`
- When showing code, use proper TypeScript syntax highlighting
- Be specific about file locations and line numbers
- Include explanatory context for why certain approaches are recommended
- When multiple attempts are shown, clearly label them and explain the reasoning

### Example Format
```markdown
## Implementation guidance

* The culprit for this is most likely `ServiceName.methodName` ([GitHub](https://github.com/repo/path/file.ts#L170)), which has the query:

```typescript
const example = await this.service.method({
  // code example
})
```

* Alternative approach: modify `OtherService.method` ([GitHub](https://github.com/repo/path/other.ts#L42))
* When implementing across venues, clear the property. When implementing within the same venue, preserve it.
```
