---
model: sonnet
name: daily-brief
description: "Generate a lean daily brief from Slack, Linear, Google Calendar, Google Drive, and the Obsidian vault, then write it to today's journal note (`Area/Journal/YYYY-MM-DD.md`). When today has a retro or a long-gap (monthly-ish) 1:1 (Kim, Tal, Adrian), also write a detailed prep note to `Area/Journal/Daily Prep/` covering everything since the last occurrence. Use when invoked at 3am via cron, or manually as `/daily-brief`, 'run daily brief', or 'regenerate today's brief'."
---

# Daily Brief

End-to-end automated briefing. Pulls overnight signal from connected systems, cross-references for gaps, and writes a markdown brief into Paul's daily Obsidian note.

Designed for headless `claude -p` invocation from a 3am cron, but also runs interactively.

**Effort budget**: the general brief is a skim document; keep it cheap and tight (caps below are hard limits). Spend the saved effort on **deep prep**: when today's calendar has a retro or a long-gap 1:1, produce a detailed prep note reconstructing what happened since the last occurrence. Deep prep is the most valuable output of this skill; the general brief is second.

## Inputs (resolve at runtime)

```
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d)
THIS_MONTH=$(date +%Y-%m)
LAST_MONTH=$(date -v-1m +%Y-%m)
WINDOW_START_ISO=$(date -v-24H -u +%Y-%m-%dT%H:%M:%SZ)
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
OUT=/Users/paul/meandu/Area/Journal/${TODAY}.md
LOG_DIR=/Users/paul/meandu/Area/Journal/.brief-log
LOG=${LOG_DIR}/${TODAY}.log
mkdir -p "$LOG_DIR"
```

## Output target

The brief lives between markers inside `$OUT`:

```
<!-- daily-brief:start -->
... brief content ...
<!-- daily-brief:end -->
```

On re-run the same day, replace **only** that block. Preserve any content the user has typed outside it. If `$OUT` doesn't exist yet, create it containing just the block.

## Bug-report channels (cross-reference source)

These five Slack channel IDs are scanned in step 2a for bug-shaped posts without a Linear ticket:

```
C016J6YHQQ1
C015H7GANLX
C04LT4WHP0A
C08KKBKRQ1M
C041AFTTH3L
```

## Meeting classification

Every event on today's calendar falls into exactly one tier. Classify right after fetching events (step 1c); the tier drives how much prep each event gets.

**ROUTINE: no prep, schedule line only.** Title matches (case-insensitive) any of: `standup`, `geoguessr`, `social`, `team time`, `hour of power`, `game&u`, `personal commitment`, `upskilling`, `huddle`, `showcase`, `focus`, `lunch`. Also any event where Paul is the only attendee.

**DEEP-PREP: full prep note in `Area/Journal/Daily Prep/`.** Any of:

- Title contains `retro` (case-insensitive). Known series: `CAD Sprint Retro` (fortnightly, Ctrl-alt-delight team), `Product Leadership Retro/WIP` (PLT).
- A 1:1 (per the 1:1 detection rule in 2c) whose **previous occurrence of the same series is ≥21 days before today** (long-gap 1:1: the "what happened since we last spoke" reconstruction is the whole value).
- Title matches one of the **named monthly-ish 1:1s**, regardless of measured gap: `Paul / Kim`, `Paul / Tal`, `Paul C x Adrian`.

Exception: `Monthly CAD Stability steering` is prepped interactively via the dedicated `cad-stability-checkpoint` skill. Don't deep-prep it here; render a light-prep entry with a reminder line: `Run the cad-stability-checkpoint skill to prep this.`

**LIGHT-PREP: compact 3-bullet entry in the brief.** Everything else: weekly/fortnightly direct-report 1:1s (Alex, Arjay, Blake, Daryll, Edgardo, Kayleigh, Stephanie, Tatiana, Victoria, Walter, Ben, ...), ad-hoc meetings, customer/venue meetings.

Cap: at most **2 deep preps per run**. If more qualify, prioritise 1:1s over retros (a retro has 14 other attendees; a 1:1 has none), and downgrade the rest to LIGHT-PREP with a note in the brief that prep was skipped for budget.

## Workflow

### Step 1: Fetch sources (parallel, fail-soft)

Run all five fetches in parallel. If any single source errors, append `<source>: <error>` to `$LOG` and continue. Never abort the whole brief because one source is down.

**1a. Slack: unread mentions + threads I'm in (last 24h)**
- Resolve Paul's Slack user ID once: `mcp__claude_ai_Slack__slack_search_users` with `query: "paul@meandu.com"`. Cache the ID for the rest of this run.
- Mentions of Paul: `mcp__claude_ai_Slack__slack_search_public_and_private` with `query: "<@PAUL_ID> after:${YESTERDAY}"`.
- Threads Paul posted in: same tool with `query: "from:<@PAUL_ID> after:${YESTERDAY}"`. Read parent threads via `slack_read_thread` for at most the **8 most recent** hits; for the rest, rely on the search snippet.
- Capture per item: channel name, ts, snippet (≤200 chars), permalink, whether anyone is waiting on Paul's reply (last message in thread is from someone else, addressed to Paul or with a `?`).

**1b. Linear: assigned + subscribed + overnight changes**
- `mcp__claude_ai_Linear__list_issues` with `assignee: me`, exclude Done/Cancelled, `limit: 25`.
- `mcp__claude_ai_Linear__list_issues` with `subscriber: me`, `updatedAfter: ${WINDOW_START_ISO}`, `limit: 25`; catches mentions on subscribed tickets and overnight status changes.
- For each issue: capture id, title, team, state, updatedAt, last comment author (use `list_comments` only when the title alone isn't enough to know what changed).

**1c. Google Calendar: today's events**
- `mcp__claude_ai_Google_Calendar__list_calendars` once; identify the primary calendar.
- `mcp__claude_ai_Google_Calendar__list_events` for primary, `timeMin: ${TODAY}T00:00:00+10:00`, `timeMax: ${TODAY}T23:59:59+10:00` (Paul is AEST, see MEMORY).
- Capture per event: title, start/end, attendees (names only), description, conferencing link, any attachments.
- Classify each event per **Meeting classification** above. For each DEEP-PREP event, also find the **previous occurrence** of the same series: `list_events` with `fullText: <event title>` over the past 10 weeks, take the most recent occurrence strictly before today. Its date is `SINCE` (the deep-prep window start). Fallback if the calendar lookup fails: the date prefix of the most recent matching Granola filename. Last resort: 28 days ago for a 1:1, 14 days for a retro.

**1d. Google Drive: docs shared with me in last 24h**
- `mcp__claude_ai_Google_Drive__list_recent_files` with `pageSize: 25`.
- Keep entries whose `sharedWithMeTime` (or fallback `modifiedTime`) is within the last 24h **and** owner is not Paul.
- Capture: name, owner, mime type, webViewLink.

**1e. Obsidian: open action items**
- Read `/Users/paul/meandu/Area/Tasks.md` directly with `Read`.
- Parse every line starting `- [ ]`. Extract:
  - `📅 YYYY-MM-DD` → due date
  - `➕ YYYY-MM-DD` → created date
  - `#name` (lowercase) → person tags
  - Slack permalink if present.
- Bucket A: due date ≤ TODAY (overdue + due-today).
- Bucket B (computed in Step 2d): items whose `#name` matches an attendee on today's calendar.

### Step 2: Cross-reference

**2a. Slack bug reports without Linear tickets**

For each channel ID in the bug-report list above:

1. `mcp__claude_ai_Slack__slack_read_channel` with `channel: <id>`, `oldest: ${WINDOW_START_ISO}`.
2. For each **top-level** message (no `thread_ts` parent):
   - Score "bug-shaped" if any of: `broken`, `doesn't work`, `not working`, `error`, `errored`, `erroring`, `failed`, `incident`, `🐛`, `🐞`, `can't`, `cannot`, `breaking`, `regression`, `bug`, image/screenshot attachment with words like `error`/`screen`. Case-insensitive.
   - If bug-shaped: read the full thread via `slack_read_thread` (parent ts).
   - If **no** message in the thread contains a `linear.app/` URL, flag as a candidate ticket.
3. Capture: channel name, reporter display name, posted-at, ≤200-char snippet, permalink.

**2b. Last touchpoint for LIGHT-PREP 1:1s**

For each LIGHT-PREP 1:1 on today's calendar (skip ROUTINE events and non-1:1 meetings entirely):

- Find the most recent Granola note matching the person (1:1 detection rule in 2c) and summarise its open commitments.
- Do **not** run per-attendee Linear searches for LIGHT-PREP events; tag-matched Tasks.md items (2d) are enough.

DEEP-PREP events are handled in step 2e instead.

**2c. Overdue action items from past 1:1s**

**1:1 detection rule** (used in both 2b and 2c). A Granola filename in the scanned folders (see Scan below) is treated as a 1:1 if **any** of:

- Title (after the `YYYY-MM-DD ` date prefix) contains the literal `1:1` or `1-on-1`.
- Title matches `<X> _ Paul` (Paul as second party; Granola substitutes `/` with `_` in filenames). Examples: `Edgardo _ Paul.md`, `Sophie Chen _ Paul.md`.
- Title matches `Paul _ <Y>` (Paul as first party). Examples: `Paul _ Tal.md`, `Paul _ Kim.md`.
- Title matches `Paul C x <Y>` (Paul as first party, `x` separator). Example: `Paul C x Adrian.md`.

Important: `<X> x me&u` (e.g. `Treetop Golf x me&u`) and `me&u _ <X>` are **customer/venue meetings, not 1:1s**: exclude them.

**Scan**:

- Walk `Area/Granola/${THIS_MONTH}/*.md`. Also walk `Area/Granola/${LAST_MONTH}/*.md` when today is within the first 14 days of the month (so 1:1s spanning the month boundary aren't missed). For each filename, apply the rule above.
- For each file that qualifies, read it and extract:
  - Lines beginning `- [ ]`
  - Lines beginning `Action item:` / `Action:` / `TODO:` / `Follow up:` (case-insensitive)
- Cross-check `Tasks.md`: if the same item text (or substring ≥30 chars) is still `- [ ]` open, surface it as overdue with a wikilink to the Granola file.

**2d. Action items tied to today's meeting attendees**

For each unique attendee on today's calendar:
- Map name → first-name lowercase tag (e.g. "Dom Smith" → `#dom`).
- Filter Tasks.md open items with that tag.
- These feed the Meeting Prep section, not the general Action Items list.

**2e. Deep prep for retros and long-gap 1:1s**

For each DEEP-PREP event on today's calendar (max 2, see classification), write a standalone prep note:

```
PREP=/Users/paul/meandu/Area/Journal/Daily Prep/${TODAY} <event title>.md
```

Sanitise `/` in the event title to `_` for the filename (match the Granola convention, e.g. `Product Leadership Retro_WIP`). The window for all lookups is `SINCE .. TODAY` (from 1c).

**Retro prep** (e.g. `CAD Sprint Retro`, `Product Leadership Retro/WIP`). Goal: walk in remembering what actually happened this sprint/period, not just the last three days.

1. **Last retro's note**: read the most recent Granola note matching the retro title. Extract action items; cross-check Tasks.md and the team's Linear for whether each got done. Carried-over items are top talking points.
2. **Linear, shipped and slipped**: for `CAD Sprint Retro`, the team is Ctrl-alt-delight, id `75cf5d1a-0014-4f84-a3a2-782fb5e0f7dc`. For other retros, infer team/project scope from attendees and event description. Pull issues completed in the window, issues created-and-still-open, and anything In Progress with no update for >7 days (stalled). Bucket: shipped / carried over / stalled.
3. **Incidents and pain**: Slack search `incident after:${SINCE}` scoped to `#incident-*` channels (severity lives in Slack, never Linear). Also scan the bug-report channels list for threads in the window with heavy activity (≥5 replies). Cap 15 results total.
4. **Paul's own observations**: grep the window's journal notes (`Area/Journal/YYYY-MM-DD.md`) for content Paul typed **outside** the daily-brief markers; anything mentioning the team or its people is retro fuel.
5. Render `$PREP`:
   - `# <event title> — prep (period YYYY-MM-DD → YYYY-MM-DD)`
   - `## Since last retro`: 5-10 bullets, most memorable first: ships, incidents, misses, wins.
   - `## Carried-over actions`: each with done/open status and owner.
   - `## Stalled work`: In Progress items not progressing, with age.
   - `## Suggested talking points`: 3-5 bullets Paul could raise (start/stop/continue framing).

**Long-gap 1:1 prep** (Kim, Tal, Adrian, and any 1:1 with a ≥21-day gap). Goal: reconstruct the month so Paul isn't relying on memory for "what's happened since we last spoke".

1. **Last 1:1's note**: most recent Granola note for the person. Extract commitments both ways; mark each done/open (cross-check Tasks.md `#name` tags and Slack). Granola quirk: transcripts render "Tal" as "tau"/"tao"; treat those as Tal when scanning content.
2. **Interactions in the window**: Slack search for DMs/threads between Paul and the person (`from:<@THEIR_ID> after:${SINCE}` and `from:<@PAUL_ID>` mentioning them), cap 15. Other Granola notes in the window where both were present (scan filenames plus attendee lines).
3. **Paul's headline activity**: Linear issues Paul completed or drove in the window (assignee me, completed, cap 20) plus decisions visible in journal notes outside the brief markers. This is the "what I've been doing" half of the conversation, useful for a manager 1:1 (Kim/Tal) or peer sync (Adrian).
4. **Their world**: Linear issues/projects in the window where the person is assignee or heavily active, cap 10, only if a workspace user match exists for them.
5. Render `$PREP`:
   - `# <event title> — prep (since YYYY-MM-DD)`
   - `## Commitments from last 1:1`: each with status.
   - `## What happened since`: chronological 5-10 bullets mixing Paul's ships, shared threads, and notable events.
   - `## My updates to give`: 3-5 bullets.
   - `## Topics to raise`: 3-5 bullets, including anything open >1 cycle.

Each prep note ends with a `*Sources:*` line listing what was consulted (Granola files as `[[wikilinks]]`, Linear/Slack as counts). Prep notes are plain markdown, Australian spelling, no em dashes.

### Step 3: Compose the brief

Render in this exact order. **Skip a section entirely if it would be empty** (don't print an empty heading).

```markdown
<!-- daily-brief:start -->
# Daily Brief — ${TODAY}

*Generated ${NOW_ISO}. Sources: Slack ✅/❌ · Linear ✅/❌ · Calendar ✅/❌ · Drive ✅/❌ · Vault ✅. Errors: `[[${LOG}]]` (only if non-empty)*

## Decisions Needed

For each: one bold line stating the call to make, then 1–2 supporting bullets and a copy-paste prompt.

- **<topic, ≤80 chars>** — <one-line context>
  - Source: [<channel/issue>](<link>)
  - Suggested next: `<copy-paste prompt for /morning, /linear-write, etc.>`

What lands here: Slack threads where someone is awaiting Paul's call; Linear tickets where Paul is assigned in `Triage` or where a reviewer requested changes; calendar invites awaiting RSVP; conflicts.

## Action Items Owed

Render every bullet in this section as plain markdown (no surrounding backticks), so `#name` person tags and `[[wikilinks]]` resolve to live links in Obsidian.

### Overdue / due today
- [YYYY-MM-DD] <verbatim task text from Tasks.md> *(link to source)*

### Tied to today's meetings
- [#name] <task text> *(link to source)*, for each open task tagged with a person on today's calendar.

### Surfaced from recent 1:1s
- [<person>, 1:1 on YYYY-MM-DD] <action item from Granola>, *still open in Tasks.md*. Link to `[[<Granola filename without .md>]]`.

## Suggested Linear Tickets to Create

For each Slack candidate from step 2a:

- **#<channel-name> — <one-line summary>**
  - Reporter: <display name>, posted <relative time, e.g. "8h ago">
  - Snippet: > <first 200 chars>
  - Permalink: <url>
  - Suggested next: `/linear-write Create a ticket from this Slack post: <permalink>`

## Today's schedule

One line per ROUTINE event: `- HH:MM <title>`. No prep bullets.

## Meeting Prep

DEEP-PREP events first (they're why Paul opens the brief), then LIGHT-PREP, chronological within each.

For each DEEP-PREP event:

### HH:MM — <title> 🔍
- Prep: [[<prep note filename without .md>]]
- <top 3 talking points lifted from the prep note, one bullet each>

For each LIGHT-PREP event (max 3 bullets, omit any that are empty):

### HH:MM — <title>
- Attendees: <comma list of first names>
- Last touchpoint: [[<Granola filename>]] (YYYY-MM-DD) *or* "no prior notes in vault"
- Open commitments: <inline list from 2b/2d> *or* "none tracked"

## Drive activity

*Only render if non-empty.*

- [<doc name>](<link>) — shared by <owner>, <relative time>, <mime type>

<!-- daily-brief:end -->
```

### Step 4: Write atomically

1. Read existing `$OUT` (empty string if missing).
2. If marker block exists: replace its contents with the new brief (between, not including, the markers).
3. Else: create the file with the marker block first, then a blank line, then the existing content (if any).
4. Use `Write` to overwrite the whole file.
5. If `$LOG` ended up non-empty, the brief's status line will already point to it via the `[[…]]` wikilink.

### Step 5: Final output

Print **only** absolute paths to stdout, one per line: `$OUT` first, then any prep notes written in 2e. No preamble. The cron wrapper logs those paths.

## Failure modes

- **All sources failed** (cron auth dead, MCP offline): write a brief whose body is just `> All data sources failed. See [[${LOG}]]`. Exit 0 so cron doesn't retry-loop.
- **Vault path missing**: log to stderr and exit 1. This is a real config error.
- **Permission denied on a Slack channel**: log just that channel; continue with the others.
- **MCP tool name guess is wrong**: list available tools matching the prefix and pick the closest match by description. Don't silently skip the source.

## Test mode

If invoked with the literal string `--dry-run` in the prompt:

- Write to `/Users/paul/meandu/Area/Journal/.brief-test/${TODAY}.md` instead of the real journal.
- Write prep notes to `.brief-test/` too (same filename convention).
- Otherwise identical behaviour.

To force a deep prep regardless of today's calendar (for testing or ad-hoc use), invoke with e.g. `deep prep for Paul / Kim` or `deep prep for CAD Sprint Retro`; run only step 2e for that event, using the most recent past occurrence as `SINCE` and the next upcoming occurrence as the meeting date.

Useful for validating prompt changes without clobbering today's note.

## Notes

- Keep section bodies tight. The brief is for skim, not narrative: bullets over paragraphs.
- Priority order when time/tokens run short: deep prep notes → Decisions Needed → Action Items → everything else. Cut Drive activity and Suggested Linear Tickets before cutting prep depth.
- Suggested Linear Tickets: cap at 5 candidates (most recent first).
- Australian spelling.
- Don't paraphrase Slack/Linear content beyond the snippet; quote directly so attribution is preserved.
- Channel names (not IDs) in the rendered output. Resolve via the Slack search/read response.
- Times in AEST (UTC+10) when shown to the user; use ISO UTC only in metadata.
