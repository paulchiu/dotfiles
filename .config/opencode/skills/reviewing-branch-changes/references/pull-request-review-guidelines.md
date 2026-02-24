# Pull Request Review Guidelines

## Pull Request Guidelines

### Description

- Write an in-depth PR description focused on the WHY.
- Explain why the change exists and how it maps to the related card/story.
- Identify stakeholders and expected impact.
- Include media when useful (screenshots, recordings, or Loom).

### Sizing

- Keep PRs as small as practical.
- Prefer incremental PRs that build on each other.
- If work cannot be split, explain the coupling and call out whether a walkthrough is needed.

### Tests

- Most changes should include tests.
- Unit tests are expected; add integration tests where practical.
- If tests are not added, provide explicit justification.

### AI-Generated Tests

- Review all AI-generated tests before committing.
- Use iterative, small-scope prompts.
- Match existing test and mocking patterns.

## Reviewing Guidelines

### Code Quality

- Leave the codebase in a better state than you found it.
- Keep logic simple and readable (KISS).
- Use clear naming and maintainable structure.
- Prefer code that is easy to test.
- Avoid unnecessary mutation.

### YAGNI

- Avoid speculative code.
- Remove unused code when found.
- Reuse existing utilities/libraries rather than re-implementing.

### TypeScript

- Prefer `undefined` over `null` for TS/non-React code.
- Prefer `null` over `undefined` in React rendering paths.
- Avoid `any`; prefer `unknown`.
- Follow repo conventions for type vs interface usage.
- Use explicit function types where team conventions expect them.

### Testing Quality

- Tests should be readable and reflect user-facing behavior and edge cases.
- Align mocking style with nearby tests.
- Prefer meaningful assertions over broad snapshots/object dumps.

## Comment Types

- `nitpick`: minor and optional polish.
- `suggestion`: non-blocking improvement.
- `question`: clarification request.
- `blocking`: must be addressed before merge.

Use comment prefixes when they help clarify expected action and urgency.
