---
name: gcalcli-calendar
description: Manages Google Calendar events using gcalcli command-line tool. Use when adding, listing, searching, deleting, or viewing calendar events from the terminal.
---

# Gcalcli Calendar Manager

## Overview

This skill enables management of Google Calendar events using the gcalcli command-line interface. It provides quick access to common calendar operations like adding multi-day leave events, listing agendas, searching events, and deleting events.

## Prerequisites

- gcalcli must be installed (`pip install gcalcli[vobject]` or `pipx install gcalcli[vobject]`)
- Google API OAuth authentication must be completed (first run will prompt for this)
- Config file can be created at `~/.gcalclirc` for default settings

## Quick Start

### Common Operations

**Add a multi-day leave event:**
```bash
gcalcli --calendar "Calendar Name" add \
    --title "Event Name" \
    --when "YYYY-MM-DD" \
    --duration N \
    --allday \
    --noprompt
```

**List events for next 7 days:**
```bash
gcalcli --calendar "Calendar Name" agenda
```

**Search for events in a date range:**
```bash
gcalcli --calendar "Calendar Name" search "Event Name" MM/DD/YYYY MM/DD/YYYY
```

**Delete events (interactive):**
```bash
gcalcli --calendar "Calendar Name" delete "Event Name" start_date end_date
```

**Show monthly calendar view:**
```bash
gcalcli --calendar "Calendar Name" calm
```

**Show weekly calendar view:**
```bash
gcalcli --calendar "Calendar Name" calw
```

## Detailed Usage

### Adding Events

#### Multi-Day All-Day Events (e.g., Leave/Time Off)

For leave requests spanning multiple days:

```bash
gcalcli --calendar "CAD Leave" add \
    --title "Blake AL" \
    --when "2026-03-26" \
    --duration 5 \
    --allday \
    --noprompt
```

**Key flags:**
- `--when "YYYY-MM-DD"` - Start date of the event
- `--duration N` - Number of days (when using `--allday`)
- `--allday` - Creates an all-day event (ignores time component)
- `--noprompt` - Don't prompt for missing data
- `--calendar "Name"` - Target specific calendar (required if multiple calendars exist)

#### Quick Add (Natural Language)

```bash
gcalcli --calendar "Calendar Name" quick "tomorrow 2pm Meeting with team"
gcalcli --calendar "Calendar Name" quick "03/26/2026 Blake AL"
```

Note: Quick add may create single-day events even if a range is specified. Use the `add` command with `--duration` for reliable multi-day events.

#### Interactive Add

```bash
gcalcli --calendar "Calendar Name" add
```

This will prompt for title, when, duration, and other details interactively.

### Listing and Viewing Events

#### Agenda View

List events in a date range:

```bash
# Next 7 days
gcalcli --calendar "CAD Leave" agenda

# Specific date range
gcalcli --calendar "CAD Leave" agenda 03/25/2026 04/25/2026

# From specific date
gcalcli --calendar "CAD Leave" agenda 03/25/2026
```

#### Calendar Views

```bash
# ASCII monthly calendar
gcalcli --calendar "CAD Leave" calm

# ASCII weekly calendar
gcalcli --calendar "CAD Leave" calw
```

#### Search with Details

```bash
# Basic search
gcalcli --calendar "CAD Leave" search "Blake AL" 03/25/2026 04/25/2026

# With event length details
gcalcli --calendar "CAD Leave" search "Blake AL" 03/25/2026 04/25/2026 --details time --details length

# With all details
gcalcli --calendar "CAD Leave" search "Blake AL" 03/25/2026 04/25/2026 --details all
```

**Available detail flags:**
- `--details time` - Show time information
- `--details length` - Show event duration
- `--details id` - Show event ID
- `--details location` - Show location
- `--details description` - Show description
- `--details all` - Show all available details

### Deleting Events

#### Interactive Deletion

```bash
gcalcli --calendar "CAD Leave" delete "Blake AL" 03/25/2026 04/25/2026
```

This will show each matching event and prompt for confirmation:
- `[N]o` - Skip this event
- `[y]es` - Delete this event
- `[q]uit` - Stop deletion process

#### Automated Deletion (Scripted)

To delete without interactive prompts, pipe "y" responses:

```bash
echo -e "y\ny\ny" | gcalcli --calendar "CAD Leave" delete "Blake AL" 03/25/2026 04/25/2026
```

Or delete specific dates one at a time:

```bash
echo "y" | gcalcli --calendar "CAD Leave" delete "Event Name" 03/26/2026 03/26/2026
```

### Listing Calendars

```bash
gcalcli list
```

Shows all available calendars with their IDs and access levels.

### Editing Events

```bash
gcalcli --calendar "CAD Leave" edit "Event Name"
```

Opens interactive editor for matching events.

### Configuration

#### Config File Location

Create `~/.gcalclirc` for default settings:

```
--calendar "Default Calendar Name"
--nocolor
```

#### Environment Variables

```bash
export GCALCLI_CONFIG=~/Library/Application Support/gcalcli
```

#### Getting Help

```bash
# General help
gcalcli --help

# Command-specific help
gcalcli add --help
gcalcli search --help
gcalcli delete --help
```

## Common Workflows

### Adding Leave Events

When a user requests adding leave events:

1. **Identify the calendar** - Usually "CAD Leave" or similar
2. **Parse date ranges** - Convert from natural language (e.g., "26/03/2026 to 30/03/2026" → "2026-03-26" with duration 5)
3. **Create multi-day events** - Use `add` command with `--allday` and `--duration`
4. **Verify creation** - Use `search` with `--details length` to confirm multi-day span

**Example workflow:**
```bash
# Add first leave period
gcalcli --calendar "CAD Leave" add \
    --title "Blake AL" \
    --when "2026-03-26" \
    --duration 5 \
    --allday \
    --noprompt

# Add second leave period
gcalcli --calendar "CAD Leave" add \
    --title "Blake AL" \
    --when "2026-04-15" \
    --duration 6 \
    --allday \
    --noprompt

# Verify
gcalcli --calendar "CAD Leave" search "Blake AL" 03/25/2026 04/25/2026 --details time --details length
```

### Cleaning Up Duplicate Events

If duplicate events are created:

```bash
# List all matching events
gcalcli --calendar "CAD Leave" search "Event Name" start_date end_date --details time --details length

# Delete all matching events (interactive)
gcalcli --calendar "CAD Leave" delete "Event Name" start_date end_date

# Recreate correctly
gcalcli --calendar "CAD Leave" add --title "Event Name" --when "YYYY-MM-DD" --duration N --allday --noprompt
```

## Date Format Reference

### Input Formats

- `YYYY-MM-DD` - ISO format (recommended for scripting)
- `MM/DD/YYYY` - US format
- `mm/dd` - Short format (assumes current year)
- Relative: `today`, `tomorrow`, `next week`

**Important:** When users provide dates with slashes (e.g., `04/03/2026`), assume Australian date format **dd/mm/yyyy** (day first, then month). For example, `04/03/2026` means **4th March 2026**, not April 3rd. Always use ISO format `YYYY-MM-DD` for gcalcli commands to avoid confusion.

### Duration Calculation

When using `--allday`:
- `--duration 1` = Single day event
- `--duration 5` = 5-day event (e.g., Mon-Fri)
- Count includes all days from start date

Example: `--when "2026-03-26" --duration 5` creates event spanning March 26-30, 2026

## Troubleshooting

### Authentication Issues

If OAuth token expires:
```bash
rm -rf ~/.gcalcli_oauth
gcalcli init
```

### Duplicate Events

If `quick` creates single-day events instead of multi-day:
- Use `add` command with `--duration` instead
- Delete duplicates using `delete` command
- Recreate with proper duration

### Calendar Not Found

List available calendars:
```bash
gcalcli list
```

Then use exact calendar name with `--calendar` flag.

## Best Practices

1. **Use ISO dates (YYYY-MM-DD) in scripts** - Avoids ambiguity
2. **Verify multi-day events** - Use `--details length` to confirm duration
3. **Use `--noprompt` for automation** - Prevents interactive prompts
4. **Test deletion with dry-run** - List events before deleting
5. **Quote calendar names with spaces** - `--calendar "CAD Leave"`
6. **Use `add` instead of `quick` for leave** - More reliable for multi-day events
