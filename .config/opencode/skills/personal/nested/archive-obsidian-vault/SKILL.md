---
model: haiku
name: archive-obsidian-vault
description: "Archives monthly Obsidian vault items from Area/ and Projects/ to Archive/ with year-level grouping: combines daily journals into a monthly file, moves discussions, drawings (plus attachments), and project folders, and tucks past-month workouts into subfolders in place. Use when the user says 'archive the vault', 'archive last month', 'monthly archive', 'archive my journal', 'archive workouts', or asks to archive completed monthly work."
---

# Archive Obsidian Vault

## Overview

This skill archives one month of completed work in an Obsidian vault. It moves items from `Area/` and `Projects/` into `Archive/` using year-level grouping, handles drawing attachments, and processes journal files with the bundled Python scripts.

Follow the Workflow section below in order, step by step. Do not skip steps and do not reorder them.

**Guardrail for every step:** if any command or script exits nonzero, prints an error, or produces output you did not expect, STOP. Report the exact command and its output to the user. Do not continue to the next step.

## Archive Structure (reference)

All archive folders use **year-level grouping**:

```
Archive/
  YYYY Category/          # recurring categories grouped by year
    YYYY-MM[-DD] file.md   # items inside keep their datestamp prefix
    attachments/            # if the category has binary attachments
  YYYY[-MM[-DD]] Name      # standalone items at the archive root
```

### Recurring categories

Only create the year folders that have items to archive this run. Not every vault uses all categories.

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

### Workouts are NEVER moved to Archive/

`Area/Fitness/Workouts/` is a live Dataview source for `Area/Fitness/Fitness Dashboard.md` (queries use `FROM "Area/Fitness/Workouts"`). Moving sessions to `Archive/` silently drops them from PB calculations and per-exercise tables. Workouts stay under `Area/Fitness/Workouts/`; past months move into monthly subfolders there (see Step 7).

```
Area/Fitness/Workouts/
  2026-03/                # past month
    2026-03-16.md
  2026-04/                # past month
    2026-04-06.md
  2026-05-02.md           # current month, at the root
```

Dataview's `FROM "Area/Fitness/Workouts"` recurses into subfolders, so the dashboard keeps working without query edits.

## Workflow

### Step 0: Preconditions

1. Run all commands from the vault root (the directory that contains `Area/`, and usually `Projects/` and `Archive/`). If you are not sure which directory is the vault root, ask the user before doing anything else.
2. Check for vault-specific conventions:
   ```bash
   test -f AGENTS.md && cat AGENTS.md
   ```
   If `AGENTS.md` exists, read it fully and follow its conventions. Where AGENTS.md conflicts with this skill, AGENTS.md wins.
3. Determine which vault this is. You need this for Step 2a only:
   - If AGENTS.md names the vault, use that.
   - Else, if the vault path contains `meandu`, treat it as the **meandu (work)** vault.
   - Else, if the vault path contains `Quartz`, treat it as the **Quartz (personal)** vault.
   - Else, ask the user: "Is this the Quartz (personal) vault or the meandu (work) vault?" Wait for the answer.

### Step 1: Determine the month to archive

Do NOT ask the user which month to archive, except in the multiple-months case below.

1. Get the current month:
   ```bash
   date +%Y-%m
   ```
2. List journal files and collect their distinct `YYYY-MM` prefixes:
   ```bash
   ls Area/Journal/ | grep -E '^[0-9]{4}-[0-9]{2}' | cut -c1-7 | sort -u
   ```
3. Archivable months are the prefixes that are strictly before the current month.
4. Branch:
   - Exactly one archivable month: use it as `$MONTH`. Continue.
   - Multiple archivable months: list them and ask the user which one(s) to archive. Wait for the answer.
   - Zero archivable months: tell the user there is nothing to archive and stop (if the user only asked to archive workouts, skip to Step 7 instead).
5. Set `$YEAR` to the first 4 characters of `$MONTH` (e.g. `$MONTH` = `2026-03` gives `$YEAR` = `2026`).

### Step 2: Journal processing (bundled scripts, in this exact order)

Journals are **always** processed with the scripts bundled next to this SKILL.md. NEVER move daily journal files as-is, and NEVER combine journals by hand. The order 2a, 2b, 2c matters: extraction may create new empty files that 2b then deletes.

#### Step 2a: Extract bookmarks/links (Quartz vault ONLY)

- If this is the **meandu (work)** vault: skip this sub-step, go to Step 2b.
- If this is the **Quartz (personal)** vault: run

```bash
python ~/.config/opencode/skills/personal/nested/archive-obsidian-vault/extract_bookmarks.py Area/Journal $MONTH
```

This extracts links from journal entries into a separate `$MONTH Links.md` file and may leave some journal files empty. That is expected.

#### Step 2b: Delete empty journals (always)

Removes journal files that contain only whitespace. Run the dry run first, read its output, then run for real:

```bash
python ~/.config/opencode/skills/personal/nested/archive-obsidian-vault/delete_empty_journals.py --dry-run Area/Journal $MONTH
python ~/.config/opencode/skills/personal/nested/archive-obsidian-vault/delete_empty_journals.py Area/Journal $MONTH
```

If the dry run lists a file you would not expect to be empty (for example a file the user mentioned editing), STOP and ask the user before the real run.

#### Step 2c: Combine daily journals into a monthly file (always)

```bash
python ~/.config/opencode/skills/personal/nested/archive-obsidian-vault/combine_journals.py Area/Journal $MONTH
```

Expected result: the remaining daily `$MONTH-DD.md` files are merged into a single `Area/Journal/$MONTH Journal.md`.

### Step 3: Identify items to archive

Check each source. A missing directory or an empty glob means that category has nothing to archive this run; note it and move on (that is not an error).

```bash
ls Area/Journal/$MONTH*.md 2>/dev/null       # combined journal + any Links file
ls Area/Discussions/$MONTH*.md 2>/dev/null
ls Area/Drawings/$MONTH*.md 2>/dev/null
ls -d Projects/$MONTH* 2>/dev/null           # folders or files
```

For each Drawings file found, extract its attachment references so you can move them in Step 5:

```bash
grep -oh '!\[\[[^]]*tldrawFile[^]]*\]\]' Area/Drawings/$MONTH*.md 2>/dev/null
```

Keep the resulting list of attachment filenames (strip the `![[` and `]]`). Reference format examples:

```
![[uuid-tldrawFile.webp]]
![[uuid-tldrawFile.png]]
```

### Step 4: Create archive directories

Create a year folder ONLY for the categories that had items in Step 3:

```bash
mkdir -p "Archive/$YEAR Journals"                  # if journal files exist
mkdir -p "Archive/$YEAR Discussions"               # if discussion files exist
mkdir -p "Archive/$YEAR Drawings/attachments"      # if drawing files exist
mkdir -p "Archive/$YEAR Projects"                  # if project items exist
```

### Step 5: Move files

For each category that had items in Step 3, run its `mv`. Skip categories with no items (an unmatched glob makes `mv` fail; do not run it).

```bash
# Journals (combined monthly file + any extracted Links file)
mv Area/Journal/$MONTH*.md "Archive/$YEAR Journals/"

# Discussions
mv Area/Discussions/$MONTH*.md "Archive/$YEAR Discussions/"

# Drawings
mv Area/Drawings/$MONTH*.md "Archive/$YEAR Drawings/"

# Projects (folders or files)
mv Projects/$MONTH* "Archive/$YEAR Projects/"
```

Then move drawing attachments. For each attachment filename collected in Step 3:

1. If it is already in `Archive/$YEAR Drawings/attachments/`, do nothing (it may be there from a prior month).
2. Else look in `Projects/attachments/`. If not found there, locate it by name:
   ```bash
   find . -name "<filename>" -not -path "./Archive/*"
   ```
3. If the attachment is referenced only by this month's files, `mv` it into `Archive/$YEAR Drawings/attachments/`.
4. If it is also referenced by files from other months that are not archived yet, `cp` it instead of `mv` (never break another month's reference).
5. If an attachment cannot be found anywhere, do not fail the run. Note the missing filename and include it in the Step 6 report.

Attachment rules: all attachments for a year go directly in `Archive/$YEAR Drawings/attachments/`, flat, no nesting. If a nested `attachments/attachments/` ever appears, flatten it.

### Step 6: Verify and report

1. Count the files now in each archive directory.
2. For each archived Drawings file, confirm every `![[...]]` attachment it references exists in `Archive/$YEAR Drawings/attachments/`.
3. Check for and remove now-empty leftover source directories (e.g. an emptied `Projects/$MONTH...` folder). Do NOT remove `Area/Journal/`, `Area/Discussions/`, or `Area/Drawings/` themselves.
4. Report a summary in this shape:

```
Archived for $MONTH:
- X journal files -> Archive/$YEAR Journals/
- X discussion files -> Archive/$YEAR Discussions/
- X drawing files -> Archive/$YEAR Drawings/
- X attachment files -> Archive/$YEAR Drawings/attachments/
- X project items -> Archive/$YEAR Projects/
```

Include any missing attachments from Step 5 in the report.

### Step 7: Workouts (in place, monthly subfolders)

Run this step when the user asked to archive workouts, or when a monthly archive run finds past-month workout files at the workouts root. If `Area/Fitness/Workouts/` does not exist, skip this step.

1. Detect past-month files at the workouts root:
   ```bash
   ls Area/Fitness/Workouts/*.md 2>/dev/null
   ```
   A file is past-month when its `YYYY-MM` prefix is before the current month (from `date +%Y-%m`).
2. For each past month `$PASTMONTH` present:
   ```bash
   mkdir -p "Area/Fitness/Workouts/$PASTMONTH"
   mv Area/Fitness/Workouts/$PASTMONTH-*.md "Area/Fitness/Workouts/$PASTMONTH/"
   ```
3. Leave current-month files at the root.
4. Do NOT move workout files to `Archive/`. Do NOT combine them into a monthly file (the per-session structure is what Dataview queries).

### Step 8: iCloud re-sync check (iCloud vaults only)

Run this step ONLY if the vault path contains `Mobile Documents/iCloud~md~obsidian`. Otherwise skip it and finish.

In iCloud Drive vaults, local `mv` and `rm` (including the deletes done inside `combine_journals.py`, `delete_empty_journals.py`, and `extract_bookmarks.py`) can complete locally, then iCloud re-syncs the original files back from the cloud minutes later. Source files can reappear at `Area/Journal/`, `Area/Fitness/Workouts/`, etc. after the run looked clean.

1. Re-list each source directory for the just-archived `$MONTH`:
   ```bash
   ls Area/Journal/$MONTH*.md Area/Discussions/$MONTH*.md Area/Drawings/$MONTH*.md 2>/dev/null
   ls -d Projects/$MONTH* 2>/dev/null
   ls Area/Fitness/Workouts/$MONTH-*.md 2>/dev/null
   ```
2. If nothing reappeared, you are done.
3. For each file that reappeared, verify it is safe to delete:
   - **Daily journals**: the daily file's content must already be inside `Archive/$YEAR Journals/$MONTH Journal.md` under the matching `# YYYY-MM-DD` heading. Empty or whitespace-only files are always safe. Bookmark-only files are safe if their bookmark already lives in `$MONTH Links.md`.
   - **Workouts and other moved files**: compare against the destination copy with `diff -q`.
4. If a reappeared file is identical to (or fully captured by) its archived copy, `rm` the source copy.
5. If a daily file has content NOT in the combined journal (for example an entry edited after the archival run), STOP and ask the user. It may be a real new edit rather than a stale sync.

## Error Handling

1. **Script failure**: any bundled script exiting nonzero means STOP; report the command and its output, do not continue.
2. **Nested attachments/**: flatten if `attachments/attachments/` appears.
3. **Shared attachments**: copy (don't move) when referenced across months.
4. **Cloud sync delays**: tell the user to reload the vault (Cmd+R) if files aren't visible in Obsidian.
5. **iCloud restoring deleted/moved originals**: handled by Step 8 above.

## Best Practices

1. Always run `delete_empty_journals.py` with `--dry-run` first and read the output before the real run.
2. Verify attachment counts before and after moving.
3. Check for and remove empty directories after moving files.
4. Report a detailed summary to the user (Step 6 format).
