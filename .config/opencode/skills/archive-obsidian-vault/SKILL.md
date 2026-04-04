---
name: archive-obsidian-vault
description: Archives monthly work items from Obsidian vault Area/ and Projects/ to Archive/ with proper organization and attachment handling. Use when archiving completed monthly work.
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

## Best Practices

1. Always run `delete_empty_journals.py` with `--dry-run` first to preview
2. Verify attachment counts before and after moving
3. Check for and remove empty directories after moving files
4. Report detailed summaries to user
