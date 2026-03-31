---
name: convert-workout-journal
description: "Converts raw workout journal notes into structured Dataview-compatible fitness logs in the Obsidian vault. Use when asked to convert a workout, process a gym log, add a workout, import fitness data, or journal exercises."
---

# Convert Workout Journal

Converts raw workout journal notes into the structured fitness tracking system at `Area/Fitness/` in the Obsidian vault using deterministic Python scripts.

## Important Context

The user logs workouts manually in journal files (`Area/Journal/YYYY-MM-DD.md`) at the gym. When they ask to "journal exercises", "log workouts", or similar, they almost always mean **convert existing raw notes** from journal entries into the structured fitness system — not enter new data from scratch.

## Scripts

All conversion logic lives in `scripts/` relative to this SKILL.md:

| Script | Purpose |
|--------|---------|
| `parse_journal.py` | Parses raw journal text → structured JSON (stdout) |
| `generate_workout.py` | Takes JSON (stdin) → creates vault files |
| `exercises.json` | Canonical exercise registry (names, aliases, types) |

## Workflow

### Step 1: Identify the Journal File

Determine the date from the user's request (e.g. "yesterday's workout" → yesterday's date). The journal file is at `Area/Journal/YYYY-MM-DD.md`.

### Step 2: Parse the Journal

```bash
python3 scripts/parse_journal.py --date YYYY-MM-DD
```

JSON output goes to stdout. Warnings and unparsed lines go to stderr.

### Step 3: Review Parse Output

Check stderr output for:
- **Warnings** — exercise name corrections, unknown exercises. Show to user only if an exercise is truly unknown (not just a case correction).
- **Unparsed lines** — non-workout content from the journal. Ignore unless the user asks.

If there's a completely unknown exercise, ask the user to confirm the name and whether it's strength (sets/weight/reps) or duration. Then add it to `scripts/exercises.json`.

### Step 4: Generate Vault Files

Pipe the JSON into the generator. The script auto-suggests a workout name from the parsed data, but you can override it:

```bash
python3 scripts/parse_journal.py --date YYYY-MM-DD 2>/dev/null | python3 scripts/generate_workout.py --workout-name "Squat Day"
```

The generator creates:
1. **Workout file** at `Area/Fitness/Workouts/YYYY-MM-DD.md`
2. **Exercise files** at `Area/Fitness/Exercises/<Name>.md` (new exercises only)
3. **Dashboard sections** appended to `Area/Fitness/Fitness Dashboard.md` (new exercises only)

Use `--dry-run` to preview without writing.

### Step 5: Report

The generator prints a summary. Relay it to the user.

## When You Still Need to Intervene

- **Unknown exercise**: Parser emits a warning. Ask user for canonical name and type, update `exercises.json`.
- **Parse failures**: If the parser can't handle a journal format, fall back to reading the journal manually and constructing the JSON by hand, then pipe it to `generate_workout.py`.
- **Workout name**: The script suggests `"{First Exercise} Day"` or `"Nightly Stretch"`. Override via `--workout-name` if the user specifies something different.

## Do NOT

- Delete or overwrite existing exercise notes
- Run `generate_workout.py` without `--dry-run` if warnings indicate ambiguity
- Use DataviewJS (`$= ...`)
- Add H1 headings to workout or exercise files
