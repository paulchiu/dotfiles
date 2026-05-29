---
model: sonnet
name: morning
description: "Read today's daily brief and walk Paul through items conversationally for triage (file ticket / mark done / defer / draft reply / discuss). Use on 'morning', 'let's triage', 'walk me through today', 'morning triage', or `/morning`. Pairs with the daily-brief skill."
---

# Morning Triage

Conversational walkthrough of today's daily brief. Read what daily-brief produced and iterate item by item: file a Linear ticket, mark a task done, defer, draft a Slack reply, or discuss.

Designed to be fast: one item, one question, one action, advance.

## Workflow

### Step 1: Locate today's brief

```
TODAY=$(date +%Y-%m-%d)
BRIEF=/Users/paul/meandu/Area/Journal/${TODAY}.md
```

- If `$BRIEF` doesn't exist or doesn't contain `<!-- daily-brief:start -->`: tell Paul "No brief for today yet — want me to run `/daily-brief` first?" and stop until he confirms.
- Otherwise read the file and extract everything between the markers.

### Step 2: Parse sections

From the brief block, identify items in each section:

- **Decisions Needed** — bullet items, each with a Source link and Suggested next.
- **Action Items Owed** — three sub-buckets: Overdue/due today, Tied to today's meetings, Surfaced from recent 1:1s.
- **Suggested Linear Tickets to Create** — Slack candidates, each with a permalink.
- **Meeting Prep** — one heading per event.

Skip handled items: any line annotated with `[handled: …]` from a previous `/morning` run.

### Step 3: Triage loop

Walk sections in this order: **Decisions Needed → Suggested Linear Tickets → Action Items Owed → Meeting Prep.**

For each item:

1. Print the item compactly (≤3 lines).
2. Ask Paul **one** question: "What do you want to do?" with the natural action set for that item type (see below).
3. Execute the chosen action immediately, then advance. No summary between items.

If Paul says "skip" / "next" → move on, mark `[skipped]` in the brief.
If Paul says "stop" / "that's enough" → break the loop, go to Step 4.

#### Actions by item type

**Decisions Needed**
- *Reply on Slack* → draft via `mcp__claude_ai_Slack__slack_send_message_draft`. Show the draft to Paul; never send without explicit "send it".
- *Defer to <date>* → append `- [ ] <topic> 📅 <date>` to `Area/Tasks.md` under the Manual section.
- *Discuss* → open the conversation with Paul; once it concludes, resume the loop where it left off.
- *Mark handled* → annotate `[handled: <one-line summary>]` in the brief.

**Suggested Linear Tickets to Create**
- *Create ticket* → invoke the `linear-write` skill with the Slack permalink as input. Show the draft ticket; require Paul to confirm before saving.
- *Skip / not a bug* → annotate `[skipped: <reason>]` in the brief.
- *Discuss first* → talk it through, then re-offer.

**Action Items Owed**
- *Mark done* → edit `Area/Tasks.md` to flip the matching `- [ ]` line to `- [x]` and append ` ✅ ${TODAY}`. Match on the line's verbatim text from the brief.
- *Reschedule* → edit the `📅 YYYY-MM-DD` date on that line.
- *Reassign / hand off* → draft a Slack message to the person and tag them.
- *Discuss / skip*.

**Meeting Prep**
- *Show full prep* → read the linked Granola note, surface any open commitments, list Linear tickets tagged with the attendees.
- *Draft talking points* → write a `YYYY-MM-DD <event-title>.md` prep note in `Area/Journal/Daily Prep/` (create the folder if missing), using the daily-brief Meeting Prep bullets as a starting outline. Don't overwrite if the file already exists.
- *Skip*.

### Step 4: Wrap up

Once the loop ends:

1. Recap actions taken in **one** compact block: e.g. "Created 2 Linear tickets · Marked 3 tasks done · Deferred 1 · Drafted 4 Slack replies · Wrote 2 prep notes".
2. List any drafts that need Paul's review (Slack drafts, Linear ticket bodies, prep notes) with absolute paths or links.
3. Update the brief in place:
   - For *Meeting Prep* items where talking points were drafted: tick the `- [ ] Suggested next:` line to `- [x]`, then add a new bullet directly under it: `- Prep: [[<basename of prep note, no .md>]]`. The wikilink resolves by basename so the file path doesn't need to appear.
   - For all other handled items (Decisions Needed, Suggested Linear Tickets, Action Items): annotate with a trailing `[handled: <action>]` so re-running `/morning` later in the day won't re-prompt.
   - For *skipped* items: annotate with a trailing `[skipped]` or `[skipped: <reason>]`.

### Step 5: Final output

End with the absolute path to `$BRIEF` so Paul can click through.

## Notes

- One question at a time. Don't dump option menus; offer 2–3 likely actions with short labels.
- Never auto-send to Slack or auto-create Linear tickets. Drafts only, with explicit confirmation.
- If a Tasks.md edit can't find the matching `- [ ]` line (text drifted): tell Paul, don't guess.
- Australian spelling.
- This skill is interactive only — don't invoke it from cron.
