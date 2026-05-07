---
name: notion-anchored-comments
description: "Post block-anchored review comments on Notion pages via the Notion MCP. Use when posting RFC/doc review feedback to Notion, anchoring on code blocks or prose, replying to existing discussions, or hitting selection_with_ellipsis validation errors."
---

# Notion Anchored Comments

Post review/feedback comments on Notion pages anchored to specific blocks, not the page as a whole. Use this for RFC reviews, design-doc feedback, or any structured commentary that needs to land next to the relevant content.

## Hard Tool Constraints

The Notion MCP exposes:

- `mcp__claude_ai_Notion__notion-create-comment` — create
- `mcp__claude_ai_Notion__notion-get-comments` — read
- `mcp__claude_ai_Notion__notion-fetch` — fetch page (use `include_discussions: true` to see anchor positions)

There is **no `notion-update-comment` and no `notion-delete-comment`**. Comments are append-only via MCP. To fix a posted comment you must ask the user to delete it in the Notion UI, then repost. Never assume you can edit.

Notion comments do **not** render fenced code blocks (triple-backtick) when posted via `rich_text`. The only available code styling is the `code: true` annotation on individual rich_text segments. Plan body content accordingly (see Wrapper Format).

## Targeting Modes

`notion-create-comment` has three targeting modes — pick exactly one:

1. **Page-level**: `page_id` only. **Avoid for review feedback.** Page-level comments lose context and are usually a mistake; if anchoring fails, stop and report rather than degrade to page-level.
2. **Block-anchored**: `page_id` + `selection_with_ellipsis`. Anchors to a specific block. Whether the UI *also* captures a sub-selection within that block depends on the block type, not on anchor tightness: table cells and code blocks typically sub-select; paragraph and bullet blocks highlight the whole block regardless of how surgical the anchor looks. See *Block-type behaviour for sub-selection*.
3. **Discussion reply**: `page_id` + `discussion_id`. Replies into an existing thread. Use this when explicitly continuing a conversation rather than starting a new finding.

## selection_with_ellipsis Rules

Format: `<start>...<end>`. Notion finds the first occurrence of `<start>` and the nearest `<end>` after it. Both halves combined must match **exactly once** across the whole page.

Common failure modes (all return `validation_error: Multiple occurrences found: N occurrences`):

- Generic ends like `?? null`, `: null`, `})`, `}` — match many times in code samples.
- Identifiers that appear in multiple sections (e.g. a variable named in prose, in code, and in a checklist).
- End anchor that occurs both inside the intended span and again later (e.g. `cioanalytics.page()` inside an `if` block and again inside a callback).

Recovery recipe:

1. Read the page once with `notion-fetch` (`include_discussions: true`) so you have the full content in context.
2. Pick a `<start>` that names a specific declaration or unique phrase (`const currentPosIntegrationType`, `Blocking prerequisite`, `Flip ENABLE_CUSTOMER_IO_ANALYTICS`).
3. Pick an `<end>` that occurs exactly once **between the intended start and the next ambiguous boundary**. Closing punctuation (`):`, `).`, `:`) and uniquely-spelled identifiers help.
4. The selection must fit within a single block. You cannot anchor across blocks; pick the most representative one.
5. Snippet length only affects **uniqueness** (the start+end combo must match the page exactly once). It does **not** drive sub-selection on paragraph or bullet blocks — those highlight the whole block in the UI regardless of how tight the anchor is. See *Block-type behaviour for sub-selection* below.
6. Uniqueness matching is strict and operates on substring level, not word boundaries. A start anchor like `initi` will match every occurrence of that substring on the page (`initiative`, `initialise`, etc.), so even a single-word visual target often needs surrounding context to combine into a unique start+end pair. Verified 2026-05-06: `initi...ative` failed with `Multiple occurrences found: 3 occurrences` because `initi` appeared in `initiative` twice plus a third matching token elsewhere.

If after two attempts the selection still has multiple matches, switch the anchor to a different unique line in the same logical area rather than fighting the matcher.

## Block-type behaviour for sub-selection

`selection_with_ellipsis` always anchors at block level. Whether the UI *also* captures a sub-selection inside the block — visible in the API as a `text-context` attribute on the discussion, and in the UI as an in-block underline of the targeted phrase — depends on the **block type**, not on how tight the anchor is.

**Sub-selection captured (in-block underline)**:

- Table cells.
- Code blocks.
- Reference data point: the Fox PaaS BullMQ thread on `3563c6719946813e9fbfedf7efe77685` produced `text-context="BullMQ"` because the anchor was a single word inside a table cell.

**Sub-selection NOT captured (whole block highlights)**:

- Paragraph blocks.
- Bulleted list items.
- Heading blocks (treat as no-sub-selection until proven otherwise; not yet directly tested).
- Test data, 2026-05-06 against Notion page `3503c6719946806d9bfcffaafead7219`: three variants on the same paragraph block — long anchor (~50 char start, ~22 char end), tight ~10-char-per-side anchor, and a tightest-feasible word-scoped anchor — all returned `context="block"` with no `text-context`. The Notion UI highlighted the whole paragraph in every case.

**Implication**: tightening the anchor on a paragraph or bullet block will not produce a tighter UI highlight. Anchor tightness only matters there for uniqueness validation. Set the user's expectations up front: on prose blocks, posting a comment underlines the whole block in the UI regardless of how surgical the `selection_with_ellipsis` looks. The substance of the comment still lands correctly; readers just see a wider visual scope than the targeted sentence.

**Verifying which behaviour you got**: in `notion-get-comments` output, look at the `<discussion>` element. A `text-context="<phrase>"` attribute means Notion captured a sub-selection. Its absence means block-level highlight only — for paragraph and bullet blocks this is normal and not a failure. The create call returns success either way; the difference only shows up here.

## Block-Discussion Merging Behavior

If a block already has any discussion attached, **sub-selections within that block merge into the existing discussion** rather than spawning a new sub-anchored thread. Multiple findings on the same code block will end up as sequential comments in one thread.

Implications:

- Tell the user up-front when several findings will share a thread (e.g. multiple comments on a single code block).
- Use `discussion_id` only when intentionally replying to a specific existing thread.
- The **first** post against a fresh block creates a new discussion; later posts on the same block append.

## Wrapper Format

Use this body shape for review findings (matches the `reviewing-branch-changes` skill's `LLM note:` wrapper, adapted for Notion):

```
LLM note: <one-line summary, lowercase verb after the colon>

<paragraph: clear issue statement and concrete impact, with inline-code for files/identifiers>

Recommended change: <prose for the fix>

<optional multi-line code snippet, single rich_text segment with code: true>

(ref: <FINDING-ID>)
```

Rules:

- `LLM note:` prefix on the first line. Always.
- `(ref: <ID>)` suffix on the last line for findings with stable IDs from a checklist (e.g. `CIO-PAGE-1`). Skip the suffix for replies that are not findings.
- File paths, identifiers, function names, and code fragments → separate rich_text segments with `annotations: { code: true }`.
- Multi-line snippets → one rich_text segment with embedded `\n` and `code: true`. This renders as inline code with line breaks, the closest Notion comments get to a fenced block.
- Plain prose between code segments lives in unannotated rich_text segments.

Build the body as an array of rich_text objects, alternating plain and `code: true` segments. Example skeleton:

```json
[
  {"text": {"content": "LLM note: <summary>\n\nThe code sets "}},
  {"text": {"content": "everIdentified.current = true"}, "annotations": {"code": true}},
  {"text": {"content": " in "}},
  {"text": {"content": "components/Tracking/CustomerIoTracking.tsx"}, "annotations": {"code": true}},
  {"text": {"content": ".\n\nRecommended change: ...\n\n"}},
  {"text": {"content": "const wasIdentified = ...\nif (...) {\n  ...\n}"}, "annotations": {"code": true}},
  {"text": {"content": "\n\n(ref: CIO-PAGE-1)"}}
]
```

## Posting Workflow

1. **Fetch and orient**. Call `notion-fetch` with `include_discussions: true`. Note existing discussions, their `text-context`, and the IDs of any threads you might reply to.
2. **Test one anchor first**. Post the most-likely-tricky finding as a single test, then `notion-get-comments` (`include_all_blocks: true`) and confirm `context="block"` (not page-level) and that the discussion landed on the intended block. `text-context` will be present on table-cell and code-block anchors and absent on paragraph/bullet blocks; either is normal — its absence on prose blocks is the platform's behaviour, not a failure to retry. Tell the user up-front when posts will land on prose blocks so they expect whole-block highlighting.
3. **Post the rest**. Parallel calls are fine. Each anchored comment that lands on a fresh block creates its own discussion; ones that share a block get bundled.
4. **Verify**. Final `notion-get-comments` (`include_all_blocks: true`). Tally discussions and per-thread comment counts. Report the breakdown to the user.
5. **Stop on failure**. If anchoring repeatedly fails (multiple-occurrence errors with no good unique anchor), stop and report the limitation. Do not fall back to page-level.

## Verification Output

Default report shape after a batch post:

```
Final state — N discussions, M comments:

| Block / Discussion | Comments |
|---|---|
| <text-context excerpt> | <count> — <ID-1>, <ID-2>, ... |
...
```

Always confirm `context="block"` (never page-level) and that each discussion landed on the intended block. The `text-context` attribute will be populated on table-cell and code-block anchors and absent on paragraph and bullet blocks; treat its presence as informational, not as a pass/fail signal. Call out any thread-merging up front so the user isn't surprised, and surface in advance whenever comments will land on prose blocks (paragraph, bullet) so the user expects whole-block highlighting in the Notion UI.

## Quick Reference: Common Anchor Picks

- Code declarations: `const <varName>` is usually unique within a single code block.
- Section headings: full heading text often unique (`This PR fixes...identity model:` works, `Production rollout` alone does not).
- Bullets: lead with a distinctive opening phrase (`Blocking prerequisite...`, `Flip ENABLE_<FLAG>...`).
- Quoted strings: API names, env vars, file paths in backticks make excellent anchors when present.

## When to Use This Skill

- User asks to "post review comments to a Notion page / RFC / design doc".
- User shares a Notion URL plus a draft of review findings.
- Recovering from a previous session where comments landed page-level instead of anchored.
- After running `reviewing-branch-changes` against a doc-style target and the user wants the findings posted to Notion rather than GitHub.

## When Not to Use

- One-off page-level comment that genuinely targets the whole page (rare for reviews).
- Editing or deleting an existing comment — not possible via MCP. Tell the user to delete in the UI; repost from a corrected draft.
