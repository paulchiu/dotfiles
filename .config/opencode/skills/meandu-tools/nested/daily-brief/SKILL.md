---
model: sonnet
name: daily-brief
description: "Generate a structured daily brief from Slack, Linear, Google Calendar, Google Drive, and the Obsidian vault, then write it to today's journal note (`Area/Journal/YYYY-MM-DD.md`). Use when invoked at 3am via cron, or manually as `/daily-brief`, 'run daily brief', or 'regenerate today's brief'."
---

# Daily Brief

End-to-end automated briefing. Pulls overnight signal from connected systems, cross-references for gaps, and writes a markdown brief into Paul's daily Obsidian note.

Designed for headless `claude -p` invocation from a 3am cron, but also runs interactively.

## Inputs (resolve at runtime)

```
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d)
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

## Workflow

### Step 1: Fetch sources (parallel, fail-soft)

Run all five fetches in parallel. If any single source errors, append `<source>: <error>` to `$LOG` and continue. Never abort the whole brief because one source is down.

**1a. Slack — unread mentions + threads I'm in (last 24h)**
- Resolve Paul's Slack user ID once: `mcp__claude_ai_Slack__slack_search_users` with `query: "paul@meandu.com"`. Cache the ID for the rest of this run.
- Mentions of Paul: `mcp__claude_ai_Slack__slack_search_public_and_private` with `query: "<@PAUL_ID> after:${YESTERDAY}"`.
- Threads Paul posted in: same tool with `query: "from:<@PAUL_ID> after:${YESTERDAY}"`. For each hit, read the parent thread via `slack_read_thread` to capture replies that came in overnight.
- Capture per item: channel name, ts, snippet (≤200 chars), permalink, whether anyone is waiting on Paul's reply (last message in thread is from someone else, addressed to Paul or with a `?`).

**1b. Linear — assigned + subscribed + overnight changes**
- `mcp__claude_ai_Linear__list_issues` with `assignee: me`, exclude Done/Cancelled, `limit: 25`.
- `mcp__claude_ai_Linear__list_issues` with `subscriber: me`, `updatedAfter: ${WINDOW_START_ISO}`, `limit: 25` — catches mentions on subscribed tickets and overnight status changes.
- For each issue: capture id, title, team, state, updatedAt, last comment author (use `list_comments` only when the title alone isn't enough to know what changed).

**1c. Google Calendar — today's events**
- `mcp__claude_ai_Google_Calendar__list_calendars` once; identify the primary calendar.
- `mcp__claude_ai_Google_Calendar__list_events` for primary, `timeMin: ${TODAY}T00:00:00+10:00`, `timeMax: ${TODAY}T23:59:59+10:00` (Paul is AEST, see MEMORY).
- Capture per event: title, start/end, attendees (names only), description, conferencing link, any attachments.

**1d. Google Drive — docs shared with me in last 24h**
- `mcp__claude_ai_Google_Drive__list_recent_files` with `pageSize: 25`.
- Keep entries whose `sharedWithMeTime` (or fallback `modifiedTime`) is within the last 24h **and** owner is not Paul.
- Capture: name, owner, mime type, webViewLink.

**1e. Obsidian — open action items**
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

**2b. Calendar prep gaps**

For each of today's events with ≥2 attendees:

- Look for a Granola note matching the event title in `Area/Granola/${YYYY-MM}/` from today or yesterday.
- If no Granola note **and** the event has no description/agenda, flag as "prep gap".
- For 1:1 events (see 1:1 detection rule in 2c), always include in Meeting Prep with a summary of the last 1:1's open commitments.

**2c. Overdue action items from past 1:1s**

**1:1 detection rule** (used in both 2b and 2c). A Granola filename in `Area/Granola/${YYYY-MM}/*.md` (or last month's folder if within 14 days) is treated as a 1:1 if **any** of:

- Title (after the `YYYY-MM-DD ` date prefix) contains the literal `1:1` or `1-on-1`.
- Title matches `<X> _ Paul` (Paul as second party — Granola substitutes `/` with `_` in filenames). Examples: `Edgardo _ Paul.md`, `Sophie Chen _ Paul.md`.
- Title matches `Paul _ <Y>` (Paul as first party). Examples: `Paul _ Tal.md`, `Paul _ Kim.md`.

Important: `<X> x me&u` (e.g. `Treetop Golf x me&u`) and `me&u _ <X>` are **customer/venue meetings, not 1:1s** — exclude them.

**Scan**:

- Walk `Area/Granola/${YYYY-MM}/*.md` and `Area/Granola/$(date -v-1m +%Y-%m)/*.md` (last month if within 14-day window). For each filename, apply the rule above.
- For each file that qualifies, read it and extract:
  - Lines beginning `- [ ]`
  - Lines beginning `Action item:` / `Action:` / `TODO:` / `Follow up:` (case-insensitive)
- Cross-check `Tasks.md`: if the same item text (or substring ≥30 chars) is still `- [ ]` open, surface it as overdue with a wikilink to the Granola file.

**2d. Action items tied to today's meeting attendees**

For each unique attendee on today's calendar:
- Map name → first-name lowercase tag (e.g. "Dom Smith" → `#dom`).
- Filter Tasks.md open items with that tag.
- These feed the Meeting Prep section, not the general Action Items list.

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

## Meeting Prep

For each event on today's calendar (chronological):

### HH:MM — <title>
- Attendees: <comma list of first names>
- Last touchpoint: [[<Granola filename>]] (YYYY-MM-DD) *or* "no prior notes in vault"
- Open commitments to <person>: <bulleted list> *or* "none tracked"
- Open Linear tickets touching attendees: <bulleted list of `<id>: <title>`> *or* omit bullet
- [ ] Suggested next: `/morning prep <event title>`

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

Print **only** the absolute path to `$OUT` to stdout. No preamble. The cron wrapper logs that path.

## Failure modes

- **All sources failed** (cron auth dead, MCP offline): write a brief whose body is just `> All data sources failed. See [[${LOG}]]`. Exit 0 so cron doesn't retry-loop.
- **Vault path missing**: log to stderr and exit 1. This is a real config error.
- **Permission denied on a Slack channel**: log just that channel; continue with the others.
- **MCP tool name guess is wrong**: list available tools matching the prefix and pick the closest match by description. Don't silently skip the source.

## Test mode

If invoked with the literal string `--dry-run` in the prompt:

- Write to `/Users/paul/meandu/Area/Journal/.brief-test/${TODAY}.md` instead of the real journal.
- Otherwise identical behaviour.

Useful for validating prompt changes without clobbering today's note.

## Notes

- Keep section bodies tight. The brief is for skim, not narrative — bullets over paragraphs.
- Australian spelling.
- Don't paraphrase Slack/Linear content beyond the snippet — quote directly so attribution is preserved.
- Channel names (not IDs) in the rendered output. Resolve via the Slack search/read response.
- Times in AEST (UTC+10) when shown to the user; use ISO UTC only in metadata.
