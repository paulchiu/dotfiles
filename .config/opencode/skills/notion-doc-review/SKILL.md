---
name: notion-doc-review
description: "review a Notion doc or other types of documents."
---

# Notion Doc Review

Produce a **dated HTML review artefact**, not posted comments. Paul comments manually; the deliverable's job is to make each finding one click away from being pasted into Notion.

Auto-posting via the Notion MCP was tried and abandoned. Comments are append-only there (no update, no delete), anchoring fails unpredictably on prose blocks, and a wrong comment cannot be retracted without a UI visit. Do not reintroduce it. If asked to post, say the skill deliberately does not, and offer the copy buttons instead.

## Deliverable

One self-contained `.html` file at the sandbox root, named `yyyy-mm-dd {Title}.html`. No external assets except the mermaid CDN if diagrams are needed. Print the absolute path when done.

Build it from `assets/skeleton.html`, inlining `assets/review.css` into the `<style>` block and `assets/copy-feedback.js` into the `<script>` block. Do not rewrite either asset from memory; read and paste them.

## Reading the source doc

`notion-fetch` on a real design doc usually exceeds the token limit and gets spilled to a file. When that happens:

- Targeted lookups: `grep` the spill file directly.
- Full read: slice by character range in Python (`open(p).read()[A:B]`) in ~80,000-char spans until 100% is read. `Read`'s offset/limit will not work, the lines are too long.
- Delegate the slicing to a subagent only if the Agent tool is available and the user has not disallowed it, and be explicit about what it must return verbatim.

Re-fetch before any follow-up turn. These docs get edited mid-review, and a section that was absent yesterday may be the answer to a finding you were about to file.

## Verifying, before writing anything

Do not trust the doc's own citations. Findings that survive are the ones that were checked.

- **Code claims**: verify against `origin/main` in the named repo, not against the commit the doc pins, and say which you used. Confirm the pinned commits are still current; if they are, there is no drift excuse for a wrong citation.
- **Vendor claims**: fetch the vendor's public documentation. The highest-value findings come from the vendor contradicting the doc's premise. Check whether the doc's open questions are actually answered somewhere the author did not look.
- **Commercial and people claims** (what an operator accepted, what a team agreed): usually unverifiable. Mark them as such in the footer rather than laundering them into findings.
- Every load-bearing claim gets a citation the reader can click or paste into `git show`.

## Finding structure

Each finding is one `.finding` block with severity `blocking`, `major` or `minor`, and a stable ID (`{PREFIX}-{TOPIC}-{NN}`).

Order inside the block, and this order is what the copy button depends on:

1. `<h3>` with `.fid`, `.sev`, `.ftitle`. Title is a claim, not a topic label. "A status-code error taxonomy will record failed burns as successful", not "Error handling".
2. `<blockquote>` with the verbatim doc text, trimmed to the load-bearing clause.
3. `<p class="src">` attribution. **Link text is the platform**, `(Notion)`, `(Slack)`, `(GitHub)`, `(Toggle)`, never the document title.
4. One or more body `<p>` or `<ul>`: the finding itself. Open with the substance. Do not prefix with "The point." or any other throat-clearing label.
5. `.why` block: why it matters, consequences in order of size.
6. `.rec` block: the concrete recommended change.

Minor citation corrections carry no `.why` or `.rec` and often use a `<ul>` body. That is fine, the copy button handles it.

Do not add decision checkboxes. Paul triages by reading, not by ticking.

## The copy button

`copy-feedback.js` injects, at load, a **Copy feedback** button into every `.finding` plus one options bar above the first finding.

Copied payload:

```
Claude notes ...

_{finding body, italic}_

And recommends ...

_{recommended change, italic}_
```

Mechanics worth preserving if you edit the script:

- Two clipboard flavours. `text/html` so Notion receives real italics, code spans and links; `text/plain` markdown as the fallback, then a `document.execCommand` fallback below that.
- Parts are joined by `<p>&nbsp;</p>`. The non-breaking space is load-bearing: an empty `<p></p>` is dropped by most rich-text editors on paste and the blank lines disappear.
- The options bar has one checkbox, "Include Why this matters", off by default.
- The button needs a real user gesture. A programmatic `.click()` will fail the clipboard write, which matters when testing.

## Voice

Paul's review voice, which the artefact must sound like:

- Verdict first, in the box, before any finding.
- Lead with what is good and be specific about it. A review that only lists defects gets discounted.
- Severity is earned. Blocking means the conclusion changes, not that it annoys you.
- Name the single finding you most want taken, in the footer, and say why.
- Australian spelling. No em dashes, use commas, parentheses, colons or separate sentences.
- Backticks on every identifier, file path, flag and field name.
- Linear issues as bare codes (`RR-107`), never as links in prose.
- Do not offer to rewrite the doc. The corrections are the contribution; the labour stays with the author.
- Say plainly what you did not verify.

## Verify before handing over

1. Open the file in a browser and confirm it renders. Serving over `python3 -m http.server` and driving Chrome works; `file://` navigation is blocked for the browser tools.
2. If it has mermaid diagrams, confirm every block produced an `svg` and no block contains "Syntax error".
3. Click one **Copy feedback** button for real, paste into a `contenteditable`, and read back the block structure. Expect alternating content and `[BLANK LINE]` blocks. Do not claim the button works without this.
4. Check for em dashes and US spellings.
5. Count the findings and confirm the count in the subtitle matches.

## Archiving

Sandbox deliverables go through the `sandbox-conversation-archive` skill. Note that `archive_conversation.py` commits only the dated `.md` and its transcripts; the `.html` is not included in that pathspec and needs its own `git add` and commit.
