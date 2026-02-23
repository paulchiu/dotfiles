---
name: refining-pr-writer
description: "Refines the aichat pr-writer role based on user feedback about gpr/wpr output. Use when asked to fix, adjust, or improve PR description generation quality."
---

# Refining the PR Writer Role

Adjust the aichat `pr-writer` role so that `gpr` / `wpr` produces output matching the user's expectations.

## Context

- `gpr` is aliased to `git diff main.. | wpr`.
- `wpr` is aliased to `write_pull_request`, a zsh function at `~/.zsh/functions/write_pull_request`.
- That function pipes the diff (optionally wrapped with a `<template>`) into `aichat --role pr-writer`.
- The role file lives at `~/Library/Application Support/aichat/roles/pr-writer.md`.
- The model is configured in `~/Library/Application Support/aichat/config.yaml` (currently Haiku 4.5).

## Workflow

### Step 1: Understand the problem

1. Read the current role file: `~/Library/Application Support/aichat/roles/pr-writer.md`.
2. Ask the user what's wrong with the current output if they haven't already described it.
3. Identify which rules the model is violating (scope, formatting, backticks, template usage, checklist handling, etc.).

### Step 2: Edit the role

Apply targeted edits to the role file. Follow these principles tuned for smaller models (Haiku-class):

- **Recency bias**: Put the most critical rules at the END of the file, just before the "Start your response" line. Smaller models weight final instructions most heavily.
- **Negative examples**: Add explicit WRONG/RIGHT pairs for any rule the model keeps breaking.
- **Examples over prose**: Update the example outputs to demonstrate the desired behaviour rather than relying on prose rules alone.
- **Repetition**: If a rule is critical, state it in the body rules section AND repeat it in the critical rules section at the end.
- **Checklists**: Template checklist items must be reproduced verbatim — never checked, unchecked, reworded, or removed.
- **Backticks**: Version numbers, file names, package names, and all technical identifiers must be wrapped in backticks. Include concrete examples in the rule.
- **Scope**: The conventional commit title must always include a scope in parentheses. Include a WRONG/RIGHT pair.
- **Separator**: The `----` separator must appear on the line immediately after the title.

### Step 3: Test the change

Run the equivalent of `gpr` to verify, excluding `package-lock.json` if the diff is too large for the model's context window:

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

Check the output against this checklist:

- [ ] Title has `type(scope): Description` format (scope present).
- [ ] `----` separator on the line after the title.
- [ ] If a template was provided, every heading and checkbox line from the template appears verbatim.
- [ ] Checklist items are untouched (not checked, reworded, or removed).
- [ ] All version numbers are in backticks (e.g., `3.0.0` not 3.0.0).
- [ ] All file names are in backticks (e.g., `package.json`).
- [ ] All package names are in backticks (e.g., `@mr-yum/node-builder`).
- [ ] Every bullet point ends with a full stop.
- [ ] Australian spelling is used.
- [ ] Content is feature-focused, not file-focused.

If any check fails, go back to Step 2 and strengthen the relevant rule. Run up to 3 iterations.

### Step 5: Report

Show the user the final test output and summarise what was changed in the role file.
