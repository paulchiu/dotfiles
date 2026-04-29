---
name: dated-doc-renamer
description: "Renames notes/docs to `yyyy-mm-dd Title.md` style and, when generating or materially updating dated docs, adds lightweight reproducibility front matter with a summary prompt and optional conversation archive pointer. Use when normalising filenames, adding/preserving created-at dates, or converting slugs to sentence-case titles (preserves acronyms like CAD, US)."
---

# Dated Doc Renamer

Rename note-like files into a readable, date-prefixed format without doubling an existing date. When creating or materially updating a dated document, add compact YAML front matter that makes the document's generation process reproducible.

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
- The user asks to create, refresh, share, or make reproducible a dated document.

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

### 4. Add reproducibility front matter

When creating a new dated doc or materially changing its content, ensure it starts with YAML front matter. Rewriting sections, synthesising notes, or adding substantive decisions counts as material; fixing typos or renaming the file does not. For pure rename-only requests, preserve content unless the user asked for metadata; if a renamed document lacks reproducibility metadata, call that out briefly.

If front matter already exists, merge these fields without overwriting unrelated user metadata:

```yaml
---
title: "Readable document title"
date: "yyyy-mm-dd"
generation:
  summary_prompt: >-
    Recreate this document by producing a dated note titled "Readable document title"
    from the source context, preserving the main decisions, rationale, open questions,
    and action items.
  source_context: >-
    Short description of the inputs used, such as a conversation, raw notes, linked
    files, meeting transcript, or issue URL.
  conversation_archive:
    status: "not_applicable"
    path: null
---
```

Front matter rules:

- Keep `generation.summary_prompt` useful enough that another person or agent could regenerate a similar document without the original chat. Write it as a concise task prompt, not as a history of every step.
- Keep `generation.source_context` to 1-3 sentences or a short YAML list of source references.
- If the document was generated from a conversation, do not paste the whole conversation into the dated doc. Prefer a sidecar archive and point to it from `generation.conversation_archive.path`.
- Set `generation.conversation_archive.status` to `not_applicable` when no conversation was used, `archived` when `path` points to a sidecar archive, or `summarised_only` when a conversation existed but no sidecar archive was kept.
- If a sidecar archive is not created for a conversation, set `generation.conversation_archive.status` to `summarised_only` and put the compact source summary in `source_context`.
- Do not include secrets, credentials, private tokens, or unrelated personal context in front matter or archives.

Conversation archive pattern:

- Follow any existing repo convention first.
- Otherwise create a `conversations/` folder in the dated doc's parent directory and write the sidecar there, named with the same basename plus `.conversation.md`, for example `conversations/2026-04-21 CAD team split response draft.conversation.md`.
- Keep the archive focused: include the user's original ask, important clarifications, key assistant outputs, decisions, and final result. Omit repetitive tool chatter, failed intermediate attempts, and unrelated side discussion.
- Redact sensitive details and note redactions explicitly.
- In the dated doc, store only the relative archive path and a short source summary.

### 5. Rename safely

- Use `git mv` for tracked files.
- Use plain `mv` only for untracked files.
- Never double-prefix the date.
- Do not rename files that already match the requested convention unless the user also wants title cleanup.

### 6. Verify

After renaming or updating metadata:

- Show the final filenames.
- Check `git status --short` to confirm the rename set.
- Call out any titles that were editorial judgments rather than direct conversions.
- Call out whether reproducibility front matter was added, merged, skipped for rename-only scope, or could not be added.

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
- When printing or linking dated document paths, do not append line-number targets such as `:1`. Use plain absolute paths or clickable links that target only the file path.
