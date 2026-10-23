---
name: feedback-friday
description: "Weekly Feedback Friday prep: who to give, request or place feedback for, from the past week."
disable-model-invocation: true
---

# Feedback Friday

Writes Paul's weekly feedback suggestions as a dated HTML plus same-name `.md` in `~/dev/sandbox`: who to give feedback to, the drafts, who to ask, what is waiting, and what to place in GrowthOS.

## Safe by default

Read-only research. Paul gives, requests and places all feedback himself.

- No Slack or Chip messages, drafts or scheduled sends. No Linear, GitHub or Notion writes.
- No GrowthOS writes: never call `record_evidence`, `update_evidence`, `request_evidence`, `add_evidence_link`, `accept_evidence_suggestion`, `dismiss_evidence_suggestion`, `rate_*` or `post_comment`.
- If Paul later asks to post, treat it as a new task and confirm in this session first; the `growthos-evidence-citations` memory has the posting rules.

## Window

```bash
TODAY=$(date +%Y-%m-%d)
FROM=$(date -v-7d +%Y-%m-%d)
SLACK_AFTER=$(date -v-8d +%Y-%m-%d)   # Slack's after: is exclusive
OUT="/Users/paul/dev/sandbox/${TODAY} Feedback Friday suggestions"
```

Find the next Feedback Fridays event on Paul's Google Calendar (on or after today) for the slot time; give it in AEST with UTC in parentheses. If there is none, say so in the intro.

## Gather

Fan out one read-only agent per source, in parallel. Use Sonnet (not Haiku) for anything touching GrowthOS or notes. Tell every gatherer: no file writes, no artifacts, no messaging, return findings with permalinks. Only you write the doc. Summaries first; verbatim only to confirm a quote.

1. **Sandbox**: dated docs in the sandbox root and `archive/yyyy-mm/yyyy-mm-dd/` for each day in the window (PR reviews, plan reviews, retro and calibration notes). Also last week's `*Feedback Friday suggestions.md` (root or archive): don't repeat feedback already posted, and carry its open items.
2. **Granola**: `~/granola/yyyy-mm/` summaries in the window (attendees in front matter). Speaker labels can misattribute and "Tal" appears as "tau"/"tao"; mark those claims LABEL.
3. **Slack**: `from:@Paul Chiu after:$SLACK_AFTER`, Paul's team, custodianship and stream channels, PR review threads, the GrowthOS bot DM and the Chip DM (`D0B3BJJKH9B`). Read every thread you cite yourself to confirm the `ts`.
4. **GitHub and Linear**: `gh search prs --owner mr-yum --involves @me --updated ">=$FROM"`, then the reviews and threads on each; Linear issues Paul commented on in the window.
5. **GrowthOS** (read-only):
   - `assessments_feedback_recipients` with no query: manager, peers and reports with role and level. Skip-level reports show as `report`.
   - `assessments_evidence_requests_list`: incoming and Paul's outgoing requests.
   - `assessments_feedback_to_place` with `scope: team`; if `counts.org` is larger, also `scope: org`. For each item, `assessments_evidence_suggestions_list` with its `assignment_id` and `evidence_id`.
   - `assessments_evidence_suggestions_list` with only `assignment_id` for each direct report: pending "May fit elsewhere too" suggestions on posts already placed (including Paul's own).
   - `frameworks_list` then `frameworks_get` for exact capability names, and `frameworks_capability_get` for the level wording each draft quotes.
6. **Chip**: requests arrive in the Chip DM as "Chip has a feedback request from X". They are not GrowthOS requests and are answered in Chip Home.

## Doc structure

Front matter: `title`, `date`, `eyebrow` ("Feedback Fridays · <slot date>"), `subtitle`, `meta` ("Prepared <date> · Week: <from> to <today> · Read-only research; nothing sent", items split by " · "), and `generation` per the dated-doc skill.

Intro: one paragraph (slot, what the hour is for, GrowthOS for PDE and Chip for everyone else), then the marker legend: **INFERRED** (not directly evidenced), **LABEL** (rests on a Granola speaker label), **PRIVATE** (DM, group DM or private channel), **EXTERNAL** (Slack Connect).

1. **AI;DR**: table of 5 to 8 people: who, one line on what to say, channel, expected placement.
2. **Pending requests**: incoming (who, asked, about, where, status), Paul's outgoing ones, and informal asks.
3. **Feedback to place**: per item, person, author, date, a one-line excerpt, GrowthOS's suggestions (capability, level, demonstrated or growth area, confidence) and your view: agree, check the level, or dismiss (for example, an item that is only a request text). Then any "May fit elsewhere too" suggestions on placed posts. Paul acts on these in the hub.
4. **Per person**: `###` heading with name, channel and relationship; **What they did** (bullets with `[^n]`, markers here only); **Feedback** (reinforcing or redirecting, capability, value); **Draft** (blockquote); **Expected placement** (up to three lines of capability · level · demonstrated, strongly demonstrated or growth area, plus the evidence type). Close with an "Also worth a line" table.
5. **People to request feedback from**: who, worked together on, the ask in the "I'm looking for feedback on [specific thing]. Can you help me understand [what]?" form, channel.
6. **Skipped or sensitive**: calibration content, 1:1 and alignment topics, personal leave, private DM context, third-party feedback, anything better as a conversation.
7. **After you submit**: the checklist below.

Sources as `[^n]` footnotes with verified URLs.

## Drafting rules

Load `/writing-tone` before writing any draft and run its pre-flight on each. Cut phrases that tell the reader how to feel instead of saying what happened (Paul has flagged "so everyone knew where it stood" and "an honest note" as AI-slop).

- **Shape**: SBI (situation, observable behaviour, impact) in 2 to 4 sentences, from what Paul saw directly. Reinforcing opens on the behaviour ("I appreciate how you..."); redirecting uses "Going forward, I would like to see..." or "I would love to see you do more X because Y". At most one redirect, only when evidenced; anything heavier goes to section 6.
- **Capability line**: end with "I feel this shows <exact GrowthOS capability name> at your level, <short quote of that level's expectation>." For a stretch, "closer to the <next level title> expectation for <capability>". Flag next-level lines for anyone in a promotion conversation.
- **Placement-friendly** (GrowthOS's model sees only the text and the framework):
  - The text must stand alone: what, when, impact. Don't lean on the link.
  - Say the valence in words: "shows" for demonstrated, "I would like to see more" for a growth area.
  - At most three capabilities per draft, since GrowthOS suggests up to three places.
  - Quote the level's expectation wording rather than a level code; the level is what the model gets wrong most.
  - Names of people in GrowthOS are swapped for placeholders; nicknames and anyone outside GrowthOS (customers, partners, staff without an assignment) are sent as written. In drafts, use the name GrowthOS records and refer to outsiders by role or company. Doc prose can keep Paul's usual short names.
- **Citations**: plain-text `[n]` inline, then `[n]: Platform, #channel or repo, what it shows, date: URL` lines; web URLs only (Granola `web_url`, not local paths). A DM, private channel or Slack Connect line says "(private channel)". The recipient can read the post, so don't cite Paul's DMs with third parties or other reports' 1:1s.
- **Chip**: same `[n]` format (its preview mangles inline links). Use me&u values when the person has no GrowthOS assignment; if they have one, the Chip feedback lands unplaced in GrowthOS, so keep it placement-friendly.
- **Skip-level reports** are not manager feedback; suggest the evidence type for the work (`incident_response`, `code_review`, `peer_feedback`).
- No em dashes, Australian spelling, no absolute claims ("first time", "zero bugs") unless checked. Don't invent facts; mark INFERRED.

## After you submit (section 7 content)

1. GrowthOS: link the expected cells when you post, or leave a post unplaced to compare GrowthOS's suggestion with the expected placement.
2. Feedback hub > **Feedback to place**: work through **My team**, then flip to **My whole org**. Check the level on every suggestion before accepting.
3. On your own posts, check **May fit elsewhere too**; accept only what the text supports. Editing a post appears to re-run suggestions.
4. Chip: reply from Chip Home; sent Chip feedback can't be edited.

## Render and finish

1. Write the `.md` first (Obsidian-readable: one line per paragraph and list item, no hard wraps).
2. `python3 -I ~/.claude/skills/feedback-friday/scripts/md2html.py "$OUT.md" "$OUT.html"`
3. `python3 -I ~/.claude/skills/html-edit-prompt/scripts/inject-review-layer.py --html "$OUT.html"`, then `open "$OUT.html"`.
4. Scan both files for em dashes outside the review layer.
5. In the sandbox, archive per the sandbox archive skill and commit only your own files by explicit path.
6. Reply with the AI;DR people, anything pending, and both absolute paths.
