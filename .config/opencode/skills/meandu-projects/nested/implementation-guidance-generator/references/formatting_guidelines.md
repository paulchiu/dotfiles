# Implementation Guidance Formatting Guidelines

Detailed conventions for implementation guidance docs. The document template, hard rules, and file naming live in SKILL.md; this file covers the finer points.

## Writing Style

- Concise, for a senior software engineer audience.
- Imperative/infinitive form, verb-first: "To accomplish X, do Y" instead of "You should do X".
- Objective, instructional language.
- Sentence case for headings and filenames.
- Explain why an approach is recommended, not just what to change.

## Content Order Within "Implementation guidance"

1. Primary approach first: the most likely solution or entry point.
2. Alternative approaches after, each with its own code location.
3. Context and constraints last: performance implications, security considerations, breaking changes, affected dependencies, testing requirements.

## Multi-Attempt Labeling

When the doc records multiple solution attempts, label them explicitly as "attempt 1", "attempt 2", etc., and explain the reasoning behind each and why earlier attempts were superseded.

## Code Examples

- Include snippets when they clarify the problem or fix; quote the actual problematic code, not a paraphrase.
- Always tag fenced blocks with the language for syntax highlighting.
- Use checklists (`- [ ]`) for actionable item lists.

## GitHub Link Format

```
([GitHub](https://github.com/[org]/[repository]/blob/[branch]/[path/to/file.ext]#L123))
```

Examples:

```markdown
* Check the authentication logic in `UserService.authenticate` ([GitHub](https://github.com/company/project/blob/main/src/services/UserService.ts#L45))
* The database query is in `OrderRepository.findOrders` ([GitHub](https://github.com/company/project/blob/main/src/repositories/OrderRepository.js#L78))
```

## Internal Links

Link related docs in the vault with Obsidian `[[filename]]` syntax, never standard markdown links.
