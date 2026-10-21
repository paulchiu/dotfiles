---
name: growthos-alignment
description: "Build, update, regenerate or action a GrowthOS alignment doc for one of Paul's direct reports: the shared HTML page comparing their self ratings with Paul's, with recommendations, goals and next steps. Use for 'alignment doc', 'regenerate alignment', 'bump the alignment', or alignment prompts from the GrowthOS reviews note."
---

# GrowthOS alignment doc

The alignment doc is a dated HTML page in `~/dev/sandbox`, written to the report in Paul's voice (second person) and shared with them before the alignment meeting. It sits after the check-in prep doc (private, Paul only) and before the GrowthOS action. This skill is the standard for every version; the October 2026 Q3 docs are the reference builds.

## Reference builds

Reuse page code from the most recent finished doc rather than re-deriving it. As of 21 Oct 2026, in `~/dev/sandbox` (older versions in `archive/yyyy-mm/yyyy-mm-dd/`):

- Layout: `2026-10-21 Victoria GrowthOS Q3 alignment v3.html` (renderReview() compact card, `.cap.compact` CSS, LABEL/lab(), goal sort and header, criteria section, next steps).
- Settled cards, "I'll record" wording, posted markers and the post-meeting flow: `2026-10-21 Dewaun GrowthOS Q3 alignment v3.html` and `2026-10-21 Alex GrowthOS Q3 alignment v3.html`.

If a newer cycle exists, glob `~/dev/sandbox/*GrowthOS*alignment*.html` and use the latest instead.

## File naming and versions

- `yyyy-mm-dd <First name> GrowthOS <cycle> alignment v<N>.html`, where the date is the day this version was built (not the series' first date) and N follows the person's own series (Kayleigh's Q3 went v4 → v5 while others went v2 → v3).
- Once a version has been shared, bump to a new file and leave the old one unchanged. Edit in place only while a version hasn't been sent; Paul's decisions made before sending are baked into that version.
- The page's `#decision-data` version number and history match the file name.
- Subtitle names the role and team and says what changed, e.g. "Updated on the 21st of October, after the managers' calibration session on the 20th."
- Each person's archive index doc (`archive/.../<date> <Name> GrowthOS <cycle> alignment.md`) gets a dated section per version. Commit the HTML and index by explicit path (other tabs commit to the same repo).

## Page structure

In this order:

1. Title `<Full name>: <cycle> alignment`, subtitle, header line with the GrowthOS alignment state (not started, started on <date>, completed).
2. **How I've rated this round**: the rating criteria in plain words (below), split into "applying" and "interim, pending confirmation", and what the score bar means for this person.
3. Score tiles: on my ratings, on theirs, on the recommendations, each with its band. Also the recommendation under any weighting under review (e.g. 0/33/66/100), labelled as such.
4. **New since v<N-1>** (regenerations only): a short note listing new evidence per source, or saying nothing new turned up.
5. **Where we agree**: compact table.
6. **Where I've settled on your rating**, **Where I've kept a higher rating than yours**, **Where I've kept a lower rating than yours** (use "I'd land / I'd keep" while they are still recommendations). One card per differing capability.
7. **Goals**.
8. **Next steps**.
9. **Sources**: numbered footnotes with web URLs.

### Capability cards

- Compact card where the recommendation lands on the report's rating: name plus a "settled" or "to confirm" tag; one green box ("Settled: your rating (L3 / L4)" or "Recommended: ...") with the pair and score, and "mine was X / Y · score" in small text; a one-line reason with footnotes; a collapsed "Reasoning and evidence" block (prior position, new recommendation, the criterion that moved it, full reasoning, both views, evidence list, framework wording); response buttons; a note box hidden until clicked or already written; Paul's decision controls with a short note box.
- Full three-box card (theirs, mine, recommended) where the recommendation still differs from their rating.
- Every non-obvious recommendation names the criterion it rests on. When a regeneration changes a recommendation, show the previous recommendation, the new one and the criterion or new evidence that moved it.
- Where Paul's rating sits above the evidence, recommend the evidence-based rating plus an evidence-collection next step. Where the gap is opportunity, note the reason and suggest a concrete opportunity as a next step.
- Rows resting on an interim criterion or a multi-part capability carry "I'll confirm with Tal and Sophie before recording" (or whoever owns the open criterion).
- Recommendations stay recommendations: never mark a cell agreed unless Paul decided it. When Paul settles one "with the suggestion", reword that card from "I'd recommend" to "I'll record", and make the intro and section lede say which are settled and which are still recommendations.
- Decisions the report already agreed in a returned copy stay settled across regenerations. If a new criterion would question one, keep it settled and raise it with Paul.
- Cells neither side rated show "not rated" and stay out of the counts. Use the person's own level band (e.g. E3/E4, L4/L5) from `levels` and `level_prefix` in `#decision-data`.

### Rating labels

Readers see the GrowthOS dropdown labels, never API values: consistent = 'Consistently', occasional = 'Most of the time', some = 'Some of the time', none = 'Not yet'. In JS use a LABEL map and `lab()` for pairs, table cells, the above-level line and strips. In prose, single-quote the label for rating words only. Data, select option values, exact-value JSON fields and GrowthOS writes keep API values. The copy prompts may use c/o/s/n shorthand but spell out the mapping.

### Goals

- Each goal: keep, reword or close (closing is a reply, never a delete). Leave `g.decision` for Paul.
- Suggest closing (`g.rec = 'close'`) once the goal's capability is agreed (or recommended) at 'Consistently' at the current level, with a closing note naming the next step that carries the work on.
- Sort by the capability's agreed current-level credit, lowest first; tie-break on the next level, then original order.
- Header: `capability <current level> <label lowercased> · posted <date> · suggest: <action>`.
- The goals lede says they're ordered by current-level rating, lowest first, and names which are suggested to close and why.

### Next steps

- Each step is a specific action with an owner and a timing; the session closes on them.
- Recorded in GrowthOS as plain comments on the relevant capability and level, body starting "Next step:" (not "Goal:"). An existing "Goal:" comment that is really a next step is reworded with `assessments_edit_comment`, keeping its id.
- Ask Paul which steps to post before posting. Posted steps render "Added as a next-step comment in GrowthOS <date> · comment <id>", and the action prompt says not to re-post them.

### Two roles and the data block

- Role switch at the top: the report and Paul.
- Report view: a response per card, goal and step (capabilities "ok" or "discuss", goals and steps "agree" or "change", plus a note), a general notes box, one copy button. Its prompt tells their agent to copy the file to the next version, edit only their response fields and `general`, add a history entry by them, treat @cc notes as instructions, check the JSON parses, and draft (not send) a Slack DM to Paul with the file.
- Paul's view: per card a decision (recommendation, mine, theirs, custom) with a note; a version choice (keep, bump, ask); a box for a returned file's path; copy buttons "update the doc" (no GrowthOS writes) and "action in growthos". The action prompt carries the next-step comment line.
- One `#decision-data` JSON block with version and history. Bake decisions in as Paul makes them, and seed the UI from it when browser storage has no entry.

## Rating criteria

From the managers' calibration session on 20 Oct 2026 (Paul's post: https://meandu.slack.com/archives/C05659DDYRL/p1792480228786939). Check that thread for confirmation from Tal and Sophie before calling the interim ones interim; drop the label once confirmed.

Applying:

1. Rate against the capability statement; illustrations are examples, not a checklist.
2. Anchor ratings in evidence. Where judgement runs ahead of the evidence, rate on the evidence and agree an evidence-collection next step.
3. Ratings can move on evidence the report adds before or during alignment.
4. 'Consistently' at the current level is the performing bar: about 95 is performing; 75+ is progressing for someone new to the role (use only where it fits their time in role; explain the 95 bar for established people); 150+ is mastering. Explain the scoring change to anyone anchored on last cycle's numbers.
5. Close each session with documented next steps.

Interim, pending confirmation:

1. 12-month evidence window; older evidence still counts for hard skills.
2. No opportunity: rate what was shown, note the reason, agree an opportunity as a next step.
3. Multi-part capabilities are judged against the whole statement, with feedback on the missing part.
4. About three examples is a rough guide for 'Consistently', not a count.

## Scoring

none 0, some 25, occasional 50, consistent 100. Capability score = current-level credit + next-level credit × current-level credit / 100; overall = mean across capabilities. Reproduce `assessments_get` before projecting.

## Gathering (every version)

- GrowthOS re-read, read only, Sonnet or better (never Haiku): `assessments_get`, `assessments_capability_get` for every capability at current and next level with `self_carried` / `manager_carried`, `assessments_evidence_list`, `assessments_comments_list`. List anything added since the last version.
- A returned response copy (check the person's DM with Paul and the sandbox), and Granola 1:1s or huddles since the last version (summary layer first).
- For each new item, say in the reasoning which criterion it is weighed against.
- Gatherers are read-only: no file writes, no artifacts, no herdr, no messaging. Only the writing step edits the doc.

## Writing

- /writing-tone: Paul's voice, Australian spelling, no em dashes, plain language, diplomatic but honest about growth areas.
- Everything is visible to the report: no 1:1 or skip-level detail (for EMs, nothing about their own reports), nothing from Paul's private DMs with third parties, no comparisons with other team members, no personal circumstances. Don't attribute critical feedback or feedback carrying a growth point; cite their own evidence by topic. Check who said what against the source before writing it as fact.
- Private context Paul gives (e.g. how the person likes feedback) shapes the doc's style, not its content.

## Constraints

- No GrowthOS, Slack, Linear or Notion writes until Paul pastes or asks for an action prompt. Slack drafts only on Paul's go.
- Don't publish an artifact or open the doc for Paul unless he asks.
- When done, print the absolute path and reply with the rows whose recommendation changed (old → new, criterion or evidence), new evidence per source, and anything unresolved.

## Action in GrowthOS (after the meeting)

- `assessments_get` must show `participant_status` aligning; if not, stop and tell Paul (he starts alignment in the web app).
- Per capability, re-read and call `assessments_align` only where the aligned value is empty or differs from the agreed one, current and next level only. Comments are visible to the report: Paul's note, or a one-line reason where they differed; nothing for matching cells.
- Goals: keep = no change; reword Paul's = `assessments_edit_comment`; reword theirs = reply "Agreed wording: ..."; close = reply with the closing note.
- Next steps per the convention above, only those Paul picks.
- Ask before `assessments_complete_alignment`; every current-level cell needs an aligned value first. Then update the doc's header state, posted markers and ids.
