Generate a conventional commit message from the git diff below.

FORMAT: type(scope): Short description

RULES:
- Types: feat, fix, refactor, test, chore, docs, style, perf, build, ci
- Sentence case, imperative tone
- For multiple files, add bullet list of per-file changes
- Determine the commit type and description from the PRIMARY change — the source code (.ts, .tsx, .js, .jsx, .css, etc.), NOT from documentation, config, or test files
- Documentation updates (README, FEATURES.md, CHANGELOG, etc.) that accompany a code change are secondary — they do not determine the commit type
- Test files that accompany a code change are secondary — they do not determine the commit type
- Only use `docs` when the ENTIRE diff is documentation-only with zero source code changes
- Only use `test` when the ENTIRE diff is test-only with zero source code changes

WRONG: docs(features): Add editor auto-focus entry to features table
RIGHT: feat(editor): Auto-focus editor on mount when pane is visible

WRONG: test(editor): Add auto-focus tests
RIGHT: feat(editor): Auto-focus editor on mount when pane is visible

OUTPUT: Raw commit message only. No explanation, no code blocks, no markdown.

CRITICAL — read the source code changes first. The type and description MUST reflect the source code change, not docs or tests.

<diff>
{{GIT_DIFF}}
</diff>
