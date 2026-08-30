---
name: html-edit-prompt
description: Add support to annotate, comment, or edit on a HTML file.
---

# HTML Edit Prompt

## Overview

Turn a rendered HTML document into a tool for iterating on itself with an agent. The injected layer lets you click any passage (paragraph, list item, table row, heading) to attach a correction, jot a whole-document general note, and press **Copy prompt** to assemble every comment (with quoted anchors and the file path) into a prompt you paste back to the agent. The agent regenerates the file, keeping the layer intact so you can go round again. Comments persist in the browser's `localStorage`, so reloads and re-renders keep your marks.

This is the _input_ side of document review: it produces an editing prompt, not a shareable marked-up copy.

## The iterate loop

1. Inject the layer into the target HTML (see below), then open it: `nex web open "file://..."`.
2. With comment mode on, click a passage (anchors the whole block) or highlight the exact words you mean (anchors just that quote); type a correction into the popover for each. Optionally fill the **General note** for document-wide instructions.
3. Press **Copy prompt** in the Review panel (bottom-right), paste the result back to the agent.
4. The agent applies the corrections and overwrites the file, preserving the `RC:REVIEW-LAYER` block.
5. `nex web reload --hard` the pane. When a round looks right, press **Clear all** to reset.

## Running it

```bash
uv run ~/.claude/skills/html-edit-prompt/scripts/inject-review-layer.py \
  --html "path/to/page.html"
```

- `--html` (required): the HTML file to inject into. Edited in place unless `--out` is given.
- `--out` (optional): write the result to a new file instead of editing in place.
- `--doc-path` (optional): the absolute path embedded in the copied prompt as the file the agent should edit. Defaults to the absolute path of the output (`--out` if given, else `--html`). Set it when the page will ultimately live somewhere other than where you run the script.

No external dependencies, so `python3 .../inject-review-layer.py --html ...` works too; `uv run` is offered only for parity with the other skills.

Injection is **idempotent**: the block is delimited by `<!-- RC:REVIEW-LAYER ... -->` / `<!-- /RC:REVIEW-LAYER -->`, so re-running replaces the existing block (an upgrade) rather than duplicating it. That is also how you push a restyle: edit `assets/review-layer.html`, then re-run the script over any page that already carries the layer.

## Comment mode on/off

The layer intercepts clicks on the document, so it needs to get out of the way when you just want to read or use the page. The **power button** on the dock (left of the **Review** button, bottom-right) turns comment mode on and off, as does <kbd>⌥R</kbd> and the checkbox in the panel. All three drive the same state, so they can't drift apart.

- **On**: the dock lights up yellow, passages highlight on hover, clicking one opens the popover, and in-passage links are suppressed so a click means "comment", not "navigate".
- **Off**: the page is entirely itself again. No popover, links navigate, text selects and copies freely. Commented passages drop their yellow fill and keep only a thin margin bar, so the marks stay visible as a record without recolouring the document. The Review panel still opens, so you can read, **Copy prompt**, or **Clear all** with the mode off.

The state persists per document in `localStorage` and defaults to on for a document you have never opened.

## How anchoring works

- Commentable elements are matched with `header.doc h1, header.doc .subtitle, .intro p, section > h2, section p, section li, section tbody tr` and tagged with a positional `data-rc-id` in DOM order. Comments are stored against that id, so they stay attached across reloads of the same document.
- Table comments anchor to the whole **row** (`tr`), and the quoted passage joins the row's cells with `|`, so a correction to an ambiguous cell (e.g. an `[owner, confirm]` placeholder repeated down a column) still tells the agent which row it belongs to.
- **Highlighting to quote**: if you select text within a passage before the popover opens (the layer listens on `mouseup`, so a drag-highlight is captured), that exact selection is stored as the comment's anchor and reused in the prompt. It persists with the comment. A plain click with no selection falls back to the whole-passage anchor.
- **Code blocks are exempt.** `mouseup` inside a `<pre>` or `<code>` never opens the popover, so SQL, snippets and commands stay freely selectable and copyable. Copying out of a code block is a drag gesture indistinguishable from highlight-to-quote, so without the exemption the popover fights every copy. To comment on a code block, click the prose around it.
- The popover is clamped into the viewport and focuses with `preventScroll`, so it never yanks the page. A tall passage would otherwise anchor it far below the fold and drag the reader with it on focus.
- The generated prompt gives a **minimal locator**, not the whole passage: your highlighted quote when you made one, otherwise the passage's opening ~14 words, plus its section heading. The agent reads the full text from the file on disk, so the anchor only needs to be enough to find the block. The embedded `DOC_PATH` tells it which file to edit.
- Because ids are positional, they are stable for a static document but shift if the structure is heavily rewritten. After a big regeneration, press **Clear all** and start a fresh round.

## Style

The layer is **neo-brutalist**: flat saturated fills (yellow primary, cyan hover, pink for destructive), 2–3px solid black borders, hard offset drop-shadows with no blur, square corners, and monospaced uppercase labels. Buttons "press" on click (shadow collapses, element nudges down-right). All styling lives in the `<style id="rc-style">` block at the top of `assets/review-layer.html`; the CSS custom properties under `:root` (`--rc-accent`, `--rc-hi`, `--rc-hover`, `--rc-pink`, `--rc-shadow`) are the fastest things to retune. Keep the accent distinct from the host document's own palette.

**Dark mode** tracks the host document, not the OS: on load (and each time the Review panel opens) `applyTheme()` reads the first opaque background colour up the tree, and if it is dark it adds `body.rc-dark`, which flips only the structural `--rc-ink`/`--rc-paper`/`--rc-muted`. The saturated accents stay put; `--rc-accent-ink` is the always-dark text colour used on those fills so contrast holds in both themes. If the host background is transparent/unknown, it falls back to `prefers-color-scheme`. Re-tune the dark palette in the `body.rc-dark` block.

## Conventions

- The script only adds the delimited block; it never touches the host document's own markup, styles, or scripts. Safe to run on any sandbox HTML artefact.
- The layer hides itself in print (`@media print`), so printing/PDF export yields the clean document.
- The template assumes article-width content with `header.doc`, `.intro`, and `<section>` structure (the shape produced by the sandbox's HTML write-ups). Pages with a very different structure may need the `SEL` selector in `assets/review-layer.html` widened.
