---
name: dated-doc
description: "Create or rename a dated doc or dated html: `yyyy-mm-dd Title.md` / `.html`"
---

# Dated Doc

Write-ups, notes, drafts, reports and reviews are saved as **dated docs**: a date-prefixed file with a readable title.

`yyyy-mm-dd Title.md` for markdown, `yyyy-mm-dd Title.html` for a rendered page.

One space between the date and the title. Never two dates. Examples:

- `2026-04-21 CUSM-273 plan review notes.md`
- `2026-04-22 CAD team split response draft.md`
- `2026-04-21 Draft reply to Shawn's thread.html`

## When To Use

- The user asks for a **dated doc** or **dated html** (create, write up, draft, save, refresh, share).
- You are about to save any note-like artefact and need a filename for it.
- The user asks to **rename** existing notes into the date-prefixed convention.

## Naming Rule

Applies to both creating and renaming.

**Date**

- Creating: today's date. If today's date is not already in context, run `date +%Y-%m-%d`.
- Renaming: if the filename already starts with `yyyy-mm-dd`, keep that date. Otherwise take the file's created-at (birth) date: `stat -f '%SB' -t '%Y-%m-%d' "<file>"` (macOS). If `stat` fails or returns something other than `yyyy-mm-dd`, stop and ask whether to fall back to modification time. Never silently use modification time.

**Title**

- Spaces, not hyphens or underscores.
- Sentence-style phrasing, not Title Case (first word and proper nouns only).
- Keep acronyms and identifiers uppercase: `CAD`, `CUSM`, `US`, `API`.
- Keep product and code terms in their established casing: `TypeORM`, `Prisma`, `CodeRabbit`, `PaymentProcessorService`.
- Keep natural apostrophes: `Shawn's`.
- Don't editorialise beyond these rules unless asked.

**Extension**

- Creating: `.md` by default; `.html` when the user says "dated html" or the deliverable is a rendered page (a report to open in a browser, something to annotate, a shareable one-pager).
- Renaming: keep whatever extension the file already has.

**Location**

Wherever the user pointed, else the directory holding the material it came from, else `~/dev/sandbox`. Don't ask.

## Creating A Dated Doc

1. Pick the date and title per the naming rule above.
2. Write the body. For markdown, follow **Obsidian Readability** below.
3. Add the reproducibility front matter from **Reproducibility Metadata**.
4. Check the target name is free before writing: `[ -e "<name>" ] && echo "EXISTS"`. On `EXISTS`, ask before overwriting.
5. Report the **absolute path**.

## Creating A Dated HTML

Same naming rule, `.html` extension, plus:

1. Write a single self-contained file: inline CSS and JS, no build step, no external asset the user has to keep next to it.
2. YAML front matter does not render in a browser, so put the same reproducibility fields in an HTML comment immediately after `<!doctype html>`:

   ```html
   <!--
   title: Readable document title
   date: yyyy-mm-dd
   generation:
     source_context: Short description of the inputs used.
     conversation_archive:
       status: not_applicable
       path: null
   -->
   ```

3. Set `<title>` to the same readable title.
4. Report the absolute path, and give the `open "<absolute path>"` command so it is one click away.
5. If the point of the HTML is to be marked up and fed back, offer the `html-edit-prompt` skill's annotation layer rather than hand-rolling one.

## Renaming Existing Files

Any file format, not just markdown: the convention is the name, and the extension is whatever the file already is.

### Step 1: Inspect first

1. List candidates with `rg --files <directory>` (or `find <directory> -type f` if `rg` is missing). Narrow with `--glob` only when the user named a format.
2. Run `git status --short`. `fatal: not a git repository` is fine: note it, use plain `mv` below, and skip the git checks in Step 4.
3. Fix the scope to the files the user named or the pattern they described. Do NOT add other files to the batch.
4. Proceed without asking when the request is covered by the defaults here (created-at date, spaces, sentence case). Stop and ask one clarifying question if you cannot tell which files are in scope, the user wants a date source other than "existing prefix or created-at", or their pattern conflicts with `yyyy-mm-dd Title.ext`.

### Step 2: Derive the title

Use the first branch that applies:

1. Readable text file whose first non-blank line after any front matter is a `# Heading` (or an HTML `<title>`) that reads like the title: use that text.
2. That line is short descriptive prose: use it.
3. Otherwise, including every binary format, derive from the filename: strip the extension, strip any leading `yyyy-mm-dd` or `yyyy-mm-dd-` prefix, replace hyphens and underscores with spaces.

Then apply the title rules from **Naming Rule**.

### Step 3: Leave content alone

A rename-only request does not modify file content. If a renamed document has no reproducibility front matter, mention it in the final report; do not add it.

### Step 4: Rename safely (per file)

1. Skip files that already match `yyyy-mm-dd Title.ext`, unless the user also asked for title cleanup.
2. Check the target is free: `[ -e "<new-name>" ] && echo "EXISTS"`. On `EXISTS`, stop, skip that file, and report the collision. Never overwrite.
3. Check tracking: `git ls-files --error-unmatch "<file>"` (exit 0 means tracked).
4. Tracked: `git mv "<old>" "<new>"`. Untracked or not a repo: `mv "<old>" "<new>"`. Always quote both paths, they contain spaces.
5. If a rename fails, stop, report the exact error, and wait for the user before touching the next file.
6. Never double-prefix the date. `2026-04-21 2026-04-21 ...` is always a bug.

### Step 5: Verify

1. `git status --short` should show `R  old -> new` for tracked renames. Skip in a non-git directory.
2. List every final filename as an absolute path.
3. Call out titles that were editorial judgments rather than direct conversions.
4. Say, per file, whether front matter was added, merged, or skipped as rename-only.

## Reproducibility Metadata

Add this when you create a dated doc, or when you do content work on one: rewriting sections, synthesising notes, recording decisions. Typo fixes and renames alone do not count.

If the target repository defines its own front matter schema, that schema wins. Use it as written and do not merge in fields it omits.

```yaml
---
title: "Readable document title"
date: "yyyy-mm-dd"
generation:
  source_context: >-
    Short description of the inputs used, such as a conversation, raw notes, linked
    files, meeting transcript, or issue URL.
  conversation_archive:
    status: "not_applicable"
    path: null
---
```

Merge rule: if the file already has front matter, add only the missing fields. Never delete or change unrelated keys.

- `generation.source_context`: 1-3 sentences, or a short YAML list of source references.
- `generation.conversation_archive.status`: exactly one of `not_applicable` (no conversation used), `archived` (a sidecar archive exists and `path` points to it), or `summarised_only` (a conversation existed but no archive was kept, so the compact summary lives in `source_context`).
- Never paste a whole conversation into the dated doc. Use a sidecar archive and point to it.
- Never include secrets, credentials, private tokens, or unrelated personal context in front matter or archives.

**Conversation archive pattern** (only when a conversation was the source and an archive is wanted):

1. Follow any existing repo convention first. If none exists, create a `conversations/` folder beside the dated doc.
2. Name the sidecar with the same basename plus `.conversation.md`, e.g. `conversations/2026-04-21 CAD team split response draft.conversation.md`.
3. Include only: the original ask, important clarifications, key outputs, decisions, and the final result. Omit tool chatter, failed attempts, and unrelated discussion.
4. Redact sensitive details and note each redaction explicitly.
5. In the dated doc, store only the relative archive path and a short source summary.

## Obsidian Readability

Dated markdown docs are read in Obsidian, so write for Obsidian's renderer, not for an 80-column terminal.

- **Never hard-wrap prose.** One paragraph is one line; one list item is one line, however long. Obsidian reflows to the reader's pane width, so manual breaks render ragged and fight the reader's own width setting.
- **Never wrap a list item onto an indented continuation line.** Same problem plus a real failure mode: the continuation can parse as a nested block and break the list.
- **One table row per line.** A wrapped row stops being a table.
- **Blank line above and below every block**: headings, tables, lists, code fences, horizontal rules.
- **No trailing-double-space line breaks.** Use a blank line, or `<br>` in the rare case a hard break inside a paragraph is genuinely wanted.
- Match the vault's link style: `[[Wiki Links]]` inside the vault, `[text](url)` for anything external.

Editing a doc that is already hard-wrapped: unwrap it as part of the edit rather than matching the existing style. Verify afterwards that word count, table row count, heading count and list item count are unchanged.

## Guardrails

- If a command fails and the step does not say what to do, stop and report the error. Do not improvise a workaround.
- If the user says a bracketed date in their request was a placeholder description, do not search for literal brackets in filenames.
- If the user changes the naming convention mid-task, adapt the renames already staged instead of starting over.
- When two interpretations are possible, pick the one that renames fewer files, then say so.
- Do not touch files outside the requested scope.

## Output Style

- Summarise the naming rule you applied, and whether dates came from existing prefixes, created-at timestamps, or today.
- Keep the response short and concrete.
- Print every dated doc as an **absolute path** (e.g. `/Users/paul/notes/2026-04-22 CAD team split response draft.md`), not a bare filename. Previews and click-to-open only render on full paths.
- Do not append line-number targets such as `:1` to dated document paths.
