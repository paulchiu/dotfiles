---
name: dated-doc-renamer
description: "Renames notes/docs to `yyyy-mm-dd Title.md` style. Use when normalising filenames, adding/preserving created-at dates, or converting slugs to sentence-case titles (preserves acronyms like CAD, US)."
---

# Dated Doc Renamer

Rename note-like files into a readable, date-prefixed format without doubling an existing date.

Default target format:

`yyyy-mm-dd Title.md`

Examples:

- `cusm-273-review-notes.md` -> `2026-04-21 CUSM-273 plan review notes.md`
- `2026-04-22-cad-team-split-draft.md` -> `2026-04-22 CAD team split response draft.md`
- `reply-to-shawn-thread.md` -> `2026-04-21 Draft reply to Shawn's thread.md`

## When To Use

- The user asks to rename markdown notes or similar documents into a consistent date-prefixed format.
- The repo has a mix of undated files, slug-style names, and already-dated files.
- The user wants creation date used as the prefix date.
- The user wants readable spacing and sentence-style titles instead of full kebab-case.

## Workflow

### 1. Inspect first

- List candidate files before renaming.
- Check `git status --short` so you understand whether files are tracked and whether there are existing staged renames.
- Confirm the user's intended pattern if there is any ambiguity around date source, spacing, case, or file scope.

Prefer `rg --files` for repo files. Use `find` only when needed.

### 2. Derive the date

- If the filename already starts with `yyyy-mm-dd`, preserve that date and do not add another one.
- Otherwise use the file's created-at date as the prefix.
- On macOS, prefer:

```bash
stat -f '%SB %N' -t '%Y-%m-%d' <file>
```

- If created-at is unavailable, stop and ask the user before falling back to modification time.

### 3. Derive the title

Build the human-readable title in this priority order:

1. Existing `# Heading` in the file when it is clearly the document title.
2. First meaningful opening line when there is no heading.
3. Filename-derived text as a fallback.

Title rules:

- Use spaces, not hyphens.
- Keep sentence-style phrasing, not title case.
- Preserve obvious acronyms and identifiers in uppercase, for example `CAD`, `CUSM`, `US`, `API`.
- Preserve meaningful product or code terms with their established casing when obvious, for example `TypeORM`, `Prisma`, `CodeRabbit`, `PaymentProcessorService`.
- Keep apostrophes where natural, for example `Shawn's`.
- Do not mechanically expand or rewrite titles beyond what is needed for readability unless the user asks for an editorial pass.

### 4. Rename safely

- Use `git mv` for tracked files.
- Use plain `mv` only for untracked files.
- Never double-prefix the date.
- Do not rename files that already match the requested convention unless the user also wants title cleanup.

### 5. Verify

After renaming:

- Show the final filenames.
- Check `git status --short` to confirm the rename set.
- Call out any titles that were editorial judgments rather than direct conversions.

## Guardrails

- If the user says the bracketed date was a placeholder description, do not search for literal brackets.
- If the user changes the naming convention mid-task, adapt the existing staged renames instead of starting over.
- Prefer the narrowest interpretation that avoids destructive churn.
- Do not touch files outside the requested scope.

## Output Style

When reporting back:

- Summarise the naming rule you applied.
- Mention whether dates came from existing prefixes or created-at timestamps.
- Keep the response short and concrete.
- Print each renamed file as an **absolute path** (e.g. `/Users/paul/notes/2026-04-22 CAD team split response draft.md`), not a bare filename. The nex terminal only renders file previews and click-to-open on full paths.
