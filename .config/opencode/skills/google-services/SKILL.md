---
name: google-services
description: "Use local CLI tools for Gmail and Google Calendar: gog for mail, gcalcli for calendar events."
---

# Google Services

Use this skill for Google service requests handled through local CLI tools.

## Routing

- Gmail: read `references/gog-gmail.md`, then use `gog gmail ...`.
- Calendar: read `references/gcalcli-calendar.md`, then use `gcalcli ...`.
- Drive, Docs, Sheets, and Slides are not covered by this skill.

## Operating Rules

- Prefer read-only commands unless the user asks to send, draft, label, create, update, or delete.
- For Gmail, always pass `--no-input`; use `--json` or `--plain` when parsing output.
- For Calendar, use exact dates, times, calendar names, and durations where possible.
- Confirm before destructive actions unless the user gave an exact command or target.
