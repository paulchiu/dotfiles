---
name: convert-workout-journal
description: "Converts raw workout journal notes into structured Dataview-compatible fitness logs in the Obsidian vault. Use when asked to convert a workout, process a gym log, add a workout, or import fitness data."
---

# Convert Workout Journal

Converts raw/unstructured workout journal notes into the structured fitness tracking system at `Area/Fitness/` in the Obsidian vault.

## Vault Location

```
/Users/paul/Library/Mobile Documents/iCloud~md~obsidian/Documents/Quartz
```

## System Architecture

### Directory Structure

```
Area/Fitness/
├── Workouts/          # One file per session: YYYY-MM-DD.md
├── Exercises/         # One file per exercise: Exercise Name.md
└── Fitness Dashboard.md         # Dashboard with per-exercise reports, PB, volume, 1RM

Resource/Templates/Fitness/   # Workout Template.md, Exercise Template.md
```

### How It Works

- **Workouts/** stores structured logs with Dataview inline fields in bracket syntax on list items
- **Exercises/** stores one note per unique exercise, each containing a Dataview query that auto-pulls all sessions for that exercise from Workouts/
- **Fitness Dashboard.md** is the dashboard with a dedicated section per exercise (PB + recent sets table), plus volume and estimated 1RM reports
- All queries use `FLATTEN file.lists AS L` to access inline fields on list items (`L.exercise`, `L.weight`, `L.reps`, `L.set`)
- Exercises are linked with `[[wiki links]]` everywhere — headings, inline fields, and file references

### Critical Dataview Rule

Inline fields inside list items **must** use bracket syntax: `[field:: value]`. Without brackets, Dataview treats them as page-level fields, not list-item-level fields. This is the single most important rule — bare `field:: value` will silently fail inside lists.

## Workflow

### Step 1: Parse the Raw Journal

The input may be in any format. Common patterns:

- `Bench Press 65 x 6` or `65x6` or `65 kg x 6` or `65kg 6`
- Grouped under exercise names as headings or bold text
- May include notes like "last set tough" or "per hand"

**Extract from each entry:**
- Exercise name (normalize to title case)
- Weight (first number)
- Reps (second number)
- Set number (sequential per exercise block)
- Notes (any extra text)

### Step 2: Normalize Exercise Names

Normalize to canonical title-case names:

| Raw input | Canonical name |
|---|---|
| bench, bench press, bb bench | Bench Press |
| lat pull, lat pulldown | Lat Pulldown |
| squat, squats, back squat | Squat |
| db shoulder press | Dumbbell Shoulder Press |
| calve raise, calf raise | Calve Raise |
| machine row, seated row | Machine Row |

If unsure about a name, ask the user. Do not guess.

### Step 3: Create the Workout File

Create `Area/Fitness/Workouts/YYYY-MM-DD.md` (infer date from filename, frontmatter, or ask user).

Ask the user what to call this workout for the `name` field (e.g. "Push Day", "Upper Body", "Leg Day"). This appears in the dashboard's Recent Workouts table.

Read `Resource/Templates/Fitness/Workout Template.md` for the file structure. Fill in the frontmatter (`name`, `date`) and repeat the exercise/set block for each exercise in the session.

**Format rules:**
- No H1 heading (filename is self-evident)
- Each exercise gets an `## [[Exercise Name]]` heading
- Each set is a plain list item (not a task `- [ ]`) with bracket inline fields
- Fields per set: `exercise` (wiki link), `set` (number), `weight` (number), `reps` (number)
- Optional: `[notes:: text]` appended to the line if extra context exists
- One blank line between the heading and the first set, and between exercise sections

### Step 4: Create Missing Exercise Notes

For every unique exercise in the workout, check if `Area/Fitness/Exercises/<Exercise Name>.md` exists.

**If it does not exist**, create it using `Resource/Templates/Fitness/Exercise Template.md` as the base. Replace `this.file.link` references with `link("Exercise Name")` matching the actual exercise name.

**Key:** The `WHERE` clause uses `link("Exercise Name")` to match the `[[Exercise Name]]` wiki links in workout files. The file has no H1 heading — the filename serves as the title.

**Important:** The exercise file must include **both** queries from the template:
1. A `## Recent Sessions` table filtered by `AND L.set` (shows sets with weight/reps)
2. A `## Notes` table filtered by `AND L.notes` (shows workout notes for that exercise)

When replacing `this.file.link` with `link("Exercise Name")`, do so in **both** queries.

**If it already exists**, do NOT overwrite it. The user may have added cues or notes.

### Step 5: Update the Dashboard

Read `Area/Fitness/Fitness Dashboard.md`. For each new exercise that doesn't already have a section in the dashboard, add a new section **before** the `## Volume Per Workout` line:

```markdown
---

## Exercise Name

` ` `dataview
LIST WITHOUT ID "**PB:** " + max(rows.L.weight) + "kg"
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("Exercise Name")
GROUP BY true
` ` `

` ` `dataview
TABLE WITHOUT ID
  file.link AS Workout,
  L.set AS Set,
  L.weight AS Weight,
  L.reps AS Reps
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("Exercise Name")
SORT file.name DESC, L.set ASC
LIMIT 10
` ` `
```

(Remove spaces between backticks.)

**Do NOT** duplicate sections for exercises that already appear in the dashboard.

### Step 6: Validate

After processing, verify:
- Every set line has all four bracket fields: `exercise`, `set`, `weight`, `reps`
- Every `[[Exercise Name]]` link resolves to a file in `Area/Fitness/Exercises/`
- The dashboard has a section for every exercise that appears in any workout
- No H1 headings in workout or exercise files

### Step 7: Report Summary

Output:
```
Processed: YYYY-MM-DD
- X exercises, Y total sets
- New exercise notes created: [list] (or "none")
- Dashboard sections added: [list] (or "none")
- Skipped/ambiguous: [list] (or "none")
```

## Do NOT

- Delete or overwrite existing exercise notes that have user content
- Infer weights or reps if ambiguous — ask the user
- Use `exercise:: value` without brackets inside list items (Dataview won't see it)
- Use task checkboxes (`- [ ]`) — use plain list items (`-`)
- Use DataviewJS (`$= ...`) — it requires a separate setting to be enabled
- Add H1 headings to workout or exercise files
