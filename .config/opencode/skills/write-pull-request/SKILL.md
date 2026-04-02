---
name: write-pull-request
description: "Generates pull request descriptions from current branch changes against main. Use when asked to write a PR description, create a PR, or generate a pull request."
---

# PR Description Generator

Generate a pull request description from the current branch's changes compared to main.

## Prerequisites

- Must be in a git repository with a local `main` branch
- Must have commits on the current branch ahead of main

## Workflow

### Step 1: Gather Context

1. Run `git diff main...HEAD` to get the full diff.
2. Run `git log main..HEAD --oneline` to understand the commit history.
3. Check if `.github/pull_request_template.md` exists in the project root. If it does, read it as the template.
4. If no changes are found, report "No changes detected" and stop.

### Step 2: Generate the PR Description

Output exactly this structure — no wrapping code fences, no preamble, no commentary:

```
type(scope): Description
----
[body content here]
```

#### Line 1: Title

Write a conventional commit title: `type(scope): Description`

Valid types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `style`, `perf`, `build`, `ci`

- Use sentence case (capitalise first word only)
- Use imperative mood ("Add feature" not "Added feature")
- Keep under 72 characters
- **Issue code prefix**: Extract the issue code from the current branch name (e.g., `feature/cad-1438-...` yields `CAD-1438`, `fix/PAY-3080-...` yields `PAY-3080`). Always prefix the PR title with it in brackets: `[CAD-1438] type(scope): Description`. PR titles should always have the issue code prefix.

#### Line 2: Separator

Write exactly four dashes: `----`

#### Line 3+: Body

**If a PR template was found:**
- Fill in every section of the template with specific details from the diff
- Keep all original markdown formatting, checkboxes, and HTML elements intact
- Replace all placeholder text — leave nothing unfilled
- Be specific: reference actual file names, function names, and changes

**If no template was found (personal projects):**
- Open with 1–2 sentences stating what the PR does (not the problem). Use footnotes to provide supplementary context such as root cause or technical detail.
- Follow with bullet points describing **what the user/developer can now do**, not what code changed.
- End each bullet point with a full stop (period).
- End with any relevant notes (breaking changes, migration steps, follow-up work, etc.).
- Do NOT add section headings (no `## Summary`, etc.) or a Risk section.

### Risk Classification

Only include risk classification when the PR template has a "Risks" section. Do not add risk for personal projects or when no template exists.

When the template has a "Risks" section, classify using these levels:

- **None**: Pure logging, documentation, or test-only changes with zero runtime impact.
- **Low**: Removing dead code, removing feature-flagged code paths, config changes, or UI-only changes with no data/payment impact. Even if the code being removed is unused or superseded, if it *could* affect a user's experience (e.g., a venue still on an old flag), classify as Low, not None.
- **Medium**: Changes to request handling, API behaviour, data queries, or performance-sensitive paths.
- **High**: Changes to payment flows, order totals, financial calculations, or data integrity.

When in doubt, round up. "None" should only be used when there is truly zero possibility of user-visible impact.

### Writing Rules

- **Feature overview, not changelog.** Ask "what capability does this add?" not "what files did I touch?". Avoid implementation details like file paths or function names unless essential.
- **Inline code** for technical references: key names, environment variables, config values, keyboard shortcuts, CLI commands, symbols.
- **Australian spelling** throughout (e.g., "colour", "organisation", "behaviour", "authorise").

Bad (too granular):
- Add `handleOAuth` function to auth module.
- Update login component to render new button.

Good (feature-focused):
- Users can now sign in with their GitHub account.
- GitHub profile data is automatically linked to user profiles.

### Step 3: Create the Draft PR

1. Push the current branch to the remote if it hasn't been pushed yet: `git push -u origin HEAD`
2. Create the PR using `gh`:

```
gh pr create --draft --title "<title from Step 2>" --body "$(cat <<'EOF'
<body from Step 2>
EOF
)"
```

3. Output the PR URL returned by `gh`. No preamble, no commentary, just the URL.
