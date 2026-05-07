---
name: archive-obsidian-vault
description: "Archives monthly Obsidian vault items from Area/ and Projects/ to Archive/, handling attachments. Use when archiving completed monthly work."
---

# Archive Obsidian Vault

## Overview

This skill automates the archival process for monthly work items in an Obsidian vault. It moves completed work from `Area/` and `Projects/` directories to `Archive/` following a consistent year-level grouping pattern, handles attachments properly, and processes journal files.

**First step: check for an `AGENTS.md` in the vault root.** If one exists, read it and follow any vault-specific conventions it describes. The instructions below are the general process; AGENTS.md takes precedence where they conflict.

## Archive Structure

All archive folders use **year-level grouping**:

```
Archive/
  YYYY Category/          # recurring categories grouped by year
    YYYY-MM[-DD] file.md   # items inside keep their datestamp prefix
    attachments/            # if the category has binary attachments
  YYYY[-MM[-DD]] Name      # standalone items at the archive root
```

### Recurring categories

These are the categories that get a `YYYY Category/` folder. Not every vault uses all of them; only create the ones that have items to archive.

| Category       | Source                | Example archive path                          |
| -------------- | --------------------- | --------------------------------------------- |
| Journals       | `Area/Journal/`       | `Archive/2026 Journals/2026-03 Journal.md`    |
| Projects       | `Projects/`           | `Archive/2026 Projects/2026-03 AI tips.md`    |
| Drawings       | `Area/Drawings/`      | `Archive/2026 Drawings/2026-01-15 Design.md`  |
| Discussions    | `Area/Discussions/`   | `Archive/2026 Discussions/2026-02-10 Sync.md` |

### Standalone items

Items that don't fit a recurring category stay at the Archive root with a datestamp prefix at the coarsest granularity that fits:
- `Archive/2025 Bonnie/`
- `Archive/2025-10 On-call training/`
- `Archive/2024 Links.md`

### Workouts (in-place, NOT archived to Archive/)

`Area/Fitness/Workouts/` is a live Dataview source for `Area/Fitness/Fitness Dashboard.md` (queries use `FROM "Area/Fitness/Workouts"`). Moving sessions to `Archive/` silently drops them from PB calculations and per-exercise tables, so workouts are kept in place.

Past months are tucked into **monthly subfolders** under the same root; the current month stays at the root:

```
Area/Fitness/Workouts/
  2026-03/                # past month
    2026-03-16.md
    ...
  2026-04/                # past month
    2026-04-06.md
    ...
  2026-05-02.md           # current month, at the root
```

Dataview's `FROM "Area/Fitness/Workouts"` recurses into subfolders, so the dashboard keeps working without query edits.

When the user asks to archive workouts (or it surfaces as part of a monthly archive run):
1. Detect past-month files at the workouts root (`Area/Fitness/Workouts/YYYY-MM-*.md` where `YYYY-MM` is before the current month).
2. For each past month present, `mkdir -p "Area/Fitness/Workouts/$MONTH"` and `mv` matching daily files into it.
3. Leave current-month files at the root.
4. Do NOT move workout files to `Archive/`, do NOT combine them into a monthly file (the per-session structure is what Dataview queries).

## Determining the Month to Archive

Do NOT ask the user which month to archive. Instead, auto-detect:

1. List files in `Area/Journal/` matching the `YYYY-MM-DD.md` or `YYYY-MM*.md` pattern
2. Identify months that are **before the current month** (these are archivable)
3. If there is exactly **one** archivable month, use it automatically as `$MONTH`
4. If there are **multiple** archivable months, ask the user which one(s) to archive
5. If there are **none**, tell the user there is nothing to archive

Derive `$YEAR` from `$MONTH`.

## Archival Process

### Step 1: Journal Processing

Journals are **always** processed using the scripts bundled with this skill (in the same directory as this SKILL.md). Never move daily journal files as-is. The processing order matters:

#### 1a. Extract bookmarks/links (Quartz vault only)

Only run this for the **Quartz** (personal) vault, not the meandu (work) vault. This step extracts links from journal entries into a separate file, which may leave some journal files empty.

```bash
python ~/.config/opencode/skills/archive-obsidian-vault/extract_bookmarks.py Area/Journal $MONTH
```

#### 1b. Delete empty journals

Always run this. Removes journal files that contain only whitespace. Run after extraction since extraction may create new empty files.

```bash
python ~/.config/opencode/skills/archive-obsidian-vault/delete_empty_journals.py --dry-run Area/Journal $MONTH
python ~/.config/opencode/skills/archive-obsidian-vault/delete_empty_journals.py Area/Journal $MONTH
```

#### 1c. Combine daily journals into monthly file

Always run this. Merges remaining daily `YYYY-MM-DD.md` files into a single `YYYY-MM Journal.md`.

```bash
python ~/.config/opencode/skills/archive-obsidian-vault/combine_journals.py Area/Journal $MONTH
```

### Step 2: Identify Items to Archive

Search for items matching `$MONTH` in:
- `Area/Journal/$MONTH*.md` (now a single combined file after Step 1)
- `Area/Discussions/$MONTH*.md`
- `Area/Drawings/$MONTH*.md`
- `Projects/$MONTH*/`

For Drawings files, extract attachment references (pattern: `![[*-tldrawFile.*]]`) and build a list of attachments to move.

### Step 3: Create Archive Directories

Create year-level folders only if they don't already exist:

```bash
mkdir -p "Archive/$YEAR Journals"
mkdir -p "Archive/$YEAR Projects"
mkdir -p "Archive/$YEAR Drawings/attachments"  # only if drawings exist
mkdir -p "Archive/$YEAR Discussions"             # only if discussions exist
```

### Step 4: Move Files

```bash
# Journals (combined monthly file + any extracted links file)
mv Area/Journal/$MONTH*.md "Archive/$YEAR Journals/"

# Discussions
mv Area/Discussions/$MONTH*.md "Archive/$YEAR Discussions/"

# Drawings (files, then attachments)
mv Area/Drawings/$MONTH*.md "Archive/$YEAR Drawings/"
# Find and move referenced attachments into Archive/$YEAR Drawings/attachments/

# Projects (folders or files)
mv Projects/$MONTH* "Archive/$YEAR Projects/"
```

### Step 5: Verify Completion

- Count files in each archive directory
- Verify attachment references resolve
- Report summary:

```
Archived for $MONTH:
- X journal files -> Archive/$YEAR Journals/
- X discussion files -> Archive/$YEAR Discussions/
- X drawing files -> Archive/$YEAR Drawings/
- X attachment files -> Archive/$YEAR Drawings/attachments/
- X project items -> Archive/$YEAR Projects/
```

## Attachment Handling

**Reference format:**
```
![[uuid-tldrawFile.webp]]
![[uuid-tldrawFile.png]]
```

**Finding attachments:**
- Check `Archive/$YEAR Drawings/attachments/` (may already be there from prior months)
- Check `Projects/attachments/`
- Use find to locate by UUID if needed

**Rules:**
- All attachments for a year go in `Archive/$YEAR Drawings/attachments/`
- Flat structure, no nesting
- If an attachment is referenced by files in multiple months, copy rather than move

## Error Handling

1. **Nested attachments/** - flatten if `attachments/attachments/` appears
2. **Shared attachments** - copy (don't move) when referenced across months
3. **Cloud sync delays** - tell user to reload vault (Cmd+R) if files aren't visible in Obsidian
4. **iCloud restoring deleted/moved originals** - in iCloud Drive vaults (path contains `Mobile Documents/iCloud~md~obsidian`), local `mv` and `rm` (including the deletes done inside `combine_journals.py`, `delete_empty_journals.py`, and `extract_bookmarks.py`) can complete locally, then iCloud re-syncs the original files back from the cloud minutes later. The result: source files reappear at `Area/Journal/`, `Area/Fitness/Workouts/`, etc. after the archival run looked clean.
   - At the end of every archival run in such a vault, re-list each source directory for the just-archived `$MONTH`
   - For files that reappeared, verify they're safe to delete:
     - **Daily journals**: each daily file's content should already be inside the combined `Archive/$YEAR Journals/$MONTH Journal.md` (check the matching `# YYYY-MM-DD` section). Empty/whitespace-only files are always safe. Bookmark-only files are safe if their bookmark already lives in `$MONTH Links.md`.
     - **Workouts / other moved files**: `diff -q` each pair against the destination copy.
   - If identical / fully captured, `rm` the source copies
   - If a daily file has content NOT in the combined journal (e.g. an entry edited after the archival run), stop and ask the user — it may be a real new edit, not a stale sync

## Best Practices

1. Always run `delete_empty_journals.py` with `--dry-run` first to preview
2. Verify attachment counts before and after moving
3. Check for and remove empty directories after moving files
4. Report detailed summaries to user
