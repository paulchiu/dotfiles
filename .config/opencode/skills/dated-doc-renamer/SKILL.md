---
model: haiku
name: dated-doc-renamer
description: "Renames notes/docs to `yyyy-mm-dd Title.md` and adds reproducibility front matter (summary prompt, conversation archive pointer). Use when normalising filenames, preserving created-at dates, or converting slugs to sentence-case titles."
---

# Dated Doc Renamer

Rename note-like files into a readable, date-prefixed format without doubling an existing date. When creating or materially updating a dated document, add compact YAML front matter that makes the document's generation process reproducible.

Target format (always this exact shape, one space between date and title):

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

Do the steps in this exact order. Each step lists what to run, what to expect, and when to stop.

### Step 1: Inspect first

1. List candidate files. Prefer `rg`:

   ```bash
   rg --files --glob '*.md' <directory>
   ```

   If `rg` is not installed, use `find <directory> -name '*.md' -type f` instead. Expected output: one file path per line.
2. Run `git status --short` in the target directory. Expected output: status lines such as `M file.md` or `?? file.md`, or nothing when the tree is clean.
   - If it prints `fatal: not a git repository`: that is fine. Note it, use plain `mv` in Step 5, and skip the git checks in Step 6.
3. Fix the scope: only the files the user named, or files matching the pattern the user described. Do NOT add other files to the batch.
4. Decide whether you can proceed without asking:
   - If the user's request is covered by the defaults in this skill (created-at date, spaces, sentence case), proceed.
   - If you cannot tell which files are in scope, OR the user asked for a date source other than "existing prefix or created-at", OR the user described a different naming pattern that conflicts with `yyyy-mm-dd Title.md`: stop and ask one clarifying question before renaming anything.

### Step 2: Derive the date (per file)

1. If the filename already starts with a date matching `yyyy-mm-dd` (4 digits, hyphen, 2 digits, hyphen, 2 digits, e.g. `2026-04-22-...`): keep that date. Never add a second date to the name.
2. Otherwise get the file's created-at (birth) date. On macOS run:

   ```bash
   stat -f '%SB' -t '%Y-%m-%d' "<file>"
   ```

   Expected output: a single line like `2026-04-21`. Use that as the prefix date.
3. If the `stat` command fails, or the output is not in `yyyy-mm-dd` shape: stop and ask the user whether to fall back to modification time. Do NOT silently use modification time.

### Step 3: Derive the title (per file)

Use the first branch that applies:

1. Read the file. If the first non-blank line after any YAML front matter is a `# Heading` and it reads like the document's title: use the heading text.
2. Else, if the first non-blank line is a short prose line that describes the document: use that line.
3. Else, derive from the filename: strip the `.md` extension, strip any leading `yyyy-mm-dd` or `yyyy-mm-dd-` prefix, replace hyphens and underscores with spaces.

Then apply these title rules, all of them, every time:

- Use spaces, not hyphens.
- Sentence-style phrasing, not Title Case (only the first word and proper nouns capitalised).
- Keep obvious acronyms and identifiers uppercase, for example `CAD`, `CUSM`, `US`, `API`.
- Keep product or code terms in their established casing, for example `TypeORM`, `Prisma`, `CodeRabbit`, `PaymentProcessorService`.
- Keep apostrophes where natural, for example `Shawn's`.
- Do not expand or rewrite titles beyond what these rules require. Only do an editorial rewrite if the user explicitly asked for one.

### Step 4: Add reproducibility front matter

First pick the branch:

- **Branch A, rename-only request** (the user asked only to rename files): do NOT modify file content. If a renamed document has no reproducibility front matter, mention that in your final report, but do not add it.
- **Branch B, content work** (you are creating a new dated doc, rewriting sections, synthesising notes, or adding substantive decisions): ensure the document starts with this front matter. Typo fixes and renames alone do NOT count as content work.

Front matter template for Branch B:

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

Merge rule: if the file already has front matter, add only the missing fields above. Never delete or change unrelated keys the user put there.

Field rules:

- `generation.summary_prompt`: write it as a concise task prompt that would let another person or agent regenerate a similar document without the original chat. Not a step-by-step history.
- `generation.source_context`: 1-3 sentences, or a short YAML list of source references.
- `generation.conversation_archive.status`: exactly one of these three values.
  - `not_applicable`: no conversation was used.
  - `archived`: a sidecar archive exists and `path` points to it.
  - `summarised_only`: a conversation existed but no sidecar archive was kept. In this case put the compact source summary in `source_context`.
- Never paste a whole conversation into the dated doc. Use a sidecar archive and point to it from `generation.conversation_archive.path`.
- Never include secrets, credentials, private tokens, or unrelated personal context in front matter or archives.

Conversation archive pattern (only when a conversation was the source and an archive is wanted):

1. Follow any existing repo convention for conversation archives first. If none exists, create a `conversations/` folder in the dated doc's parent directory.
2. Name the sidecar with the same basename plus `.conversation.md`, for example `conversations/2026-04-21 CAD team split response draft.conversation.md`.
3. Include only: the user's original ask, important clarifications, key assistant outputs, decisions, and the final result. Omit repetitive tool chatter, failed intermediate attempts, and unrelated side discussion.
4. Redact sensitive details and note each redaction explicitly.
5. In the dated doc, store only the relative archive path and a short source summary.

### Step 5: Rename safely (per file)

1. Skip the file entirely if it already matches `yyyy-mm-dd Title.md` (date prefix, single space, readable title), unless the user also asked for title cleanup.
2. Check the target name is free:

   ```bash
   [ -e "<new-name>" ] && echo "EXISTS"
   ```

   If it prints `EXISTS`: stop, do not rename this file, and report the collision to the user. Never overwrite an existing file.
3. Check whether the file is tracked:

   ```bash
   git ls-files --error-unmatch "<file>"
   ```

   Exit code 0 means tracked; any error means untracked (or not a repo).
4. If tracked: `git mv "<old-name>" "<new-name>"`. If untracked or not a repo: `mv "<old-name>" "<new-name>"`. Always quote both paths (they contain spaces).
5. If the rename command fails for any reason: stop, report the exact error message, and do not retry with a different command or continue to the next file until the user responds.
6. Never double-prefix the date (a name like `2026-04-21 2026-04-21 ...` is always a bug).

### Step 6: Verify

After all renames and metadata updates:

1. Run `git status --short`. Expected: `R  old -> new` lines for tracked renames. Skip this in a non-git directory.
2. List every final filename.
3. Call out any titles that were editorial judgments rather than direct conversions.
4. State, for each file, whether reproducibility front matter was added, merged, skipped because the request was rename-only, or could not be added.

## Guardrails

- If any command in the workflow fails and the step does not say what to do, stop and report the error. Do not improvise a workaround.
- If the user says a bracketed date in their request was a placeholder description, do not search for literal brackets in filenames.
- If the user changes the naming convention mid-task, adapt the renames already staged instead of starting over.
- When two interpretations are possible, pick the one that renames fewer files, then say so in the report.
- Do not touch files outside the requested scope.

## Output Style

When reporting back:

- Summarise the naming rule you applied.
- Say whether dates came from existing prefixes or created-at timestamps.
- Keep the response short and concrete.
- Print each renamed file as an **absolute path** (e.g. `/Users/paul/notes/2026-04-22 CAD team split response draft.md`), not a bare filename. The nex terminal only renders file previews and click-to-open on full paths.
- Do not append line-number targets such as `:1` to dated document paths. Use plain absolute paths or clickable links that target only the file path.
