---
name: refine-aichat-role
description: "Refines aichat role prompts (committer, pr-writer, etc.) based on user feedback about output quality. Use when asked to fix, adjust, or improve any aichat role's generation quality."
---

# Refining aichat Roles

Adjust an aichat role file so that its CLI output matches the user's expectations.

## Context

- All role files live at `~/Library/Application Support/aichat/roles/<role-name>.md`.
- The model is configured in `~/Library/Application Support/aichat/config.yaml` (currently Haiku 4.5).
- Roles are invoked via `aichat --role <role-name>`, typically piped from git commands.

### Known roles and their aliases

| Role | Alias | Pipeline |
|------|-------|----------|
| `committer` | `wcm` | `git dc \| wcm` (stages and commits with generated message) |
| `pr-writer` | `wpr` / `gpr` | `git diff main.. \| wpr` (generates PR description) |

When the user mentions a specific alias or role, target that role file. If unclear, ask which role to refine.

## Workflow

### Step 1: Understand the problem

1. Read the current role file: `~/Library/Application Support/aichat/roles/<role-name>.md`.
2. Ask the user what's wrong with the current output if they haven't already described it.
3. Identify which rules the model is violating.

### Step 2: Edit the role

Apply targeted edits to the role file. Follow these principles tuned for smaller models (Haiku-class):

- **Recency bias**: Put the most critical rules at the END of the file, just before any closing tags or "Start your response" line. Smaller models weight final instructions most heavily.
- **Negative examples**: Add explicit WRONG/RIGHT pairs for any rule the model keeps breaking.
- **Examples over prose**: Update the example outputs to demonstrate the desired behaviour rather than relying on prose rules alone.
- **Repetition**: If a rule is critical, state it in the body rules section AND repeat it in the critical rules section at the end.
- **Backticks**: Version numbers, file names, package names, and all technical identifiers must be wrapped in backticks. Include concrete examples in the rule.
- **Scope**: Conventional commit titles must always include a scope in parentheses. Include a WRONG/RIGHT pair.

#### Role-specific guidance

**committer** — The commit type and description must reflect the primary source code change, not accompanying docs or tests. Only use `docs` or `test` when the entire diff is exclusively that type.

**pr-writer** — Template checklist items must be reproduced verbatim. The `----` separator must appear on the line immediately after the title. If no template, output plain prose and bullets only — no headings or checklists.

### Step 3: Test the change

Run the role against the current repo's diff to verify.

**For `committer`:**
```bash
git diff HEAD~1 -- . ':!package-lock.json' | aichat --role committer
```

**For `pr-writer`:**
```bash
git_root=$(git rev-parse --show-toplevel 2>/dev/null)
template_file="${git_root:-.}/.github/pull_request_template.md"
if [[ -f "$template_file" ]]; then
    template=$(cat "$template_file")
    { echo "<template>"; echo "$template"; echo "</template>"; echo "<diff>"; git diff main.. -- . ':!package-lock.json'; echo "</diff>"; } | aichat --role pr-writer
else
    git diff main.. -- . ':!package-lock.json' | aichat --role pr-writer
fi
```

### Step 4: Evaluate output

Check the output against the relevant checklist:

#### Common checks (all roles)
- [ ] Title has `type(scope): Description` format (scope present).
- [ ] Content is feature-focused, not file-focused.
- [ ] All file names, package names, and version numbers are in backticks.

#### committer-specific
- [ ] Type reflects the primary source code change, not docs or tests.
- [ ] Output is raw text only — no markdown formatting, no code blocks.

#### pr-writer-specific
- [ ] `----` separator on the line after the title.
- [ ] If a template was provided, every heading and checkbox line from the template appears verbatim.
- [ ] Checklist items are untouched (not checked, reworded, or removed).
- [ ] Every bullet point ends with a full stop.
- [ ] Australian spelling is used.
- [ ] If no template, no headings or checklists in output.

If any check fails, go back to Step 2 and strengthen the relevant rule. Run up to 3 iterations.

### Step 5: Report

Show the user the final test output and summarise what was changed in the role file.
