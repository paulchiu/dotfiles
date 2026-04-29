---
name: notion-anchored-comments
description: "Post block-anchored review comments on Notion pages via the Notion MCP. Use when posting RFC/doc review feedback to Notion, anchoring on specific code blocks or prose, replying to existing discussions, or recovering from selection_with_ellipsis validation errors. Covers wrapper format (LLM note + ref suffix), inline-code styling, anchor pitfalls, and verification."
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
2. **Block-anchored**: `page_id` + `selection_with_ellipsis`. Anchors to a specific block (and within the UI, often a sub-selection of that block).
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
5. The schema says "up to ~10 characters" but in practice longer (20–40 char) start/end strings are accepted and often necessary for uniqueness.

If after two attempts the selection still has multiple matches, switch the anchor to a different unique line in the same logical area rather than fighting the matcher.

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
2. **Test one anchor first**. Post the most-likely-tricky finding as a single test, then `notion-get-comments` (`include_all_blocks: true`) and confirm `context="block"` (not page-level). Only proceed once anchoring is confirmed.
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

Always confirm `context="block"`, never page-level, and call out any thread-merging up front so the user isn't surprised.

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
