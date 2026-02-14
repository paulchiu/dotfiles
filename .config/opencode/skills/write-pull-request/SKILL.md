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

#### Line 2: Separator

Write exactly four dashes: `----`

#### Line 3+: Body

**If a PR template was found:**
- Fill in every section of the template with specific details from the diff
- Keep all original markdown formatting, checkboxes, and HTML elements intact
- Replace all placeholder text — leave nothing unfilled
- Be specific: reference actual file names, function names, and changes

**If no template was found:**
- Start with 1–2 sentences explaining the purpose/motivation
- Follow with bullet points describing **what the user/developer can now do**, not what code changed
- End each bullet point with a full stop (period)
- End with any relevant notes (breaking changes, migration steps, follow-up work, etc.)

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

### Step 3: Output

Start the response directly with the type line. No "Here is", no "Sure", no explanations. Just the formatted output.
