---
name: apple-reminders
description: "Read, add, edit, complete and delete Apple Reminders and reminder lists with the remindctl CLI (public EventKit, JSON output)."
---

# Apple Reminders (remindctl)

`remindctl` (Homebrew, `steipete/tap/remindctl`) reads and writes the same reminders Paul sees in Reminders.app, syncing through iCloud. One process per command; no server.

## Rules

- Pass `--json --no-input` on every call and parse the JSON.
- Target reminders by **ID prefix** (the `id` field, first 4+ chars), never by numeric index: indexes come from the default view and shift after any change.
- Resolve relative dates yourself (`date +%Y-%m-%d`) and pass `YYYY-MM-DD` (all-day) or `YYYY-MM-DD HH:mm` (local, timed). Timed reminders get an alarm at the due time unless `--alarm` says otherwise.
- After a write, confirm with `remindctl info <id> --json` and report what changed.
- Prefer `complete` over `delete`. Before deleting, run with `--dry-run`, show Paul what would go, and only then use `--force`. Same for `list <name> --delete`.
- List names match exactly, then case-insensitively, then ignoring emoji/punctuation. If ambiguous, get the ID from `remindctl list --json` and use `--list-id`.

## Commands

```bash
remindctl list --json                         # all lists
remindctl list Work Errands --json            # reminders in lists
remindctl show today|tomorrow|week|overdue|upcoming|open|completed|all|2026-10-20 --json [--list Work]
remindctl search "invoice" --json [--list Work] [--completed]
remindctl info 4A83 --json

remindctl add "Call dentist" --list Personal --due "2026-10-20 09:00" --priority high \
  --notes "..." --url "https://..." --repeat "every 6 months" --json --no-input
remindctl add "Check mailbox" --location "address" [--leaving] [--radius 200] --json --no-input
remindctl edit 4A83 --title "..." --due 2026-10-21 --list Work --priority none --json --no-input
remindctl edit 4A83 --clear-due --clear-alarm --clear-url --no-repeat --json --no-input
remindctl edit 4A83 --incomplete --json --no-input
remindctl complete 4A83 9F1C --json --no-input
remindctl delete 4A83 --dry-run --json        # then --force once Paul confirms

remindctl list Projects --create --json --no-input
remindctl list Work --rename Office --json --no-input
```

Priority: `none|low|medium|high`. Repeat: `daily|weekly|biweekly|monthly|yearly|every N days/weeks/months/years`. `--url` is also mirrored into a `remindctl URL (managed): ...` notes line so it shows in the app.

## Not supported (by design)

Flags, tags, sections, subtasks, Urgent, smart lists and attachments have no public EventKit API, so remindctl cannot set them. Say so and ask Paul to do that part in Reminders.app. Do not fall back to AppleScript or writes to the Reminders SQLite store.

## Permissions

Check with `remindctl status --json` or `remindctl doctor --for-agent`. macOS attributes Reminders access to the responsible app, not to remindctl: inside herdr that is **Ghostty**, because herdr servers are started from Ghostty shells and herdr does not disclaim responsibility. So:

- If access is "Not determined", run `remindctl authorize` and ask Paul to click Allow on the prompt (it names Ghostty).
- If access is denied inside a pane but works in a plain Ghostty window, the herdr server was probably started by launchd. Restart it from a Ghostty shell (see the herdr skill).
- launchd jobs (e.g. `claude-scheduled`) cannot get Reminders access this way; there is no prompt for them. Do not promise unattended reminder automation without solving that first.
- remindctl upgrades do not affect the grant.

Background research: `~/dev/sandbox/2026-10-15 Apple Reminders CLI options.md`.
