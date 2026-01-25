Generate a conventional commit message from the git diff below.

FORMAT: [type](scope): [Short description]

RULES:
- Types: feat, fix, refactor, test, chore, docs, style, perf, build, ci
- Sentence case, imperative tone
- For multiple files, add bullet list of per-file changes

OUTPUT: Raw commit message only. No explanation, no code blocks, no markdown.

<diff>
{{GIT_DIFF}}
</diff>
