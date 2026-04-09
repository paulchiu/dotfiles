#!/usr/bin/env python3
"""
Generate structured Obsidian fitness files from parsed workout JSON.

Reads JSON from stdin (output of parse_journal.py) and creates/updates:
  1. Workout file:    Area/Fitness/Workouts/YYYY-MM-DD.md
  2. Exercise files:  Area/Fitness/Exercises/<Name>.md (new exercises only)
  3. Dashboard:       Area/Fitness/Fitness Dashboard.md (new sections only)
"""

import json
import re
import argparse
import signal
import sys
from pathlib import Path


DEFAULT_VAULT = "/Users/paul/Library/Mobile Documents/iCloud~md~obsidian/Documents/Quartz"


class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


def signal_handler(sig, frame):
    print("\n\nOperation cancelled by user.", file=sys.stderr)
    sys.exit(0)


def format_weight(w):
    """Format weight: int if whole number, float otherwise."""
    if isinstance(w, float) and w == int(w):
        return str(int(w))
    return str(w)


def generate_workout_content(data, workout_name):
    """Generate workout markdown file content."""
    date = data["date"]
    name = workout_name or data.get("suggested_name", "Workout")

    lines = [
        "---",
        "type: workout",
        f"date: {date}",
        f"name: {name}",
        "---",
    ]

    for exercise in data["exercises"]:
        ex_name = exercise["name"]
        ex_type = exercise.get("type", "strength")
        lines.append(f"## [[{ex_name}]]")
        lines.append("")

        if ex_type == "duration" or "duration" in exercise:
            # Duration exercise: single line
            duration = exercise["duration"]
            lines.append(f"- [exercise:: [[{ex_name}]]] [duration:: {duration}]")
        else:
            # Strength exercise
            notes = exercise.get("notes", [])
            sets = exercise.get("sets", [])

            # Notes line (join multiple notes with ". ")
            if notes:
                joined = ". ".join(notes)
                lines.append(f"- [exercise:: [[{ex_name}]]] [notes:: {joined}]")

            # Set lines
            for s in sets:
                weight = format_weight(s["weight"])
                parts = f"- [exercise:: [[{ex_name}]]] [set:: {s['set']}] [weight:: {weight}] [reps:: {s['reps']}]"
                if "notes" in s:
                    parts += f" [notes:: {s['notes']}]"
                lines.append(parts)

        lines.append("")

    # Remove trailing blank line, add final newline
    while lines and lines[-1] == "":
        lines.pop()
    return "\n".join(lines) + "\n"


def generate_exercise_content(name, ex_type):
    """Generate exercise note markdown content."""
    if ex_type == "duration":
        return f"""## Recent Sessions

```dataview
TABLE WITHOUT ID
  file.link AS Workout,
  L.duration AS "Duration (s)"
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("{name}") AND L.duration
SORT file.name DESC
LIMIT 10
```

## Notes

```dataview
TABLE WITHOUT ID
  file.link AS Workout,
  L.notes AS Notes
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("{name}") AND L.notes
SORT file.name DESC
```
"""
    else:
        return f"""## Recent Sessions

```dataview
TABLE WITHOUT ID
  file.link AS Workout,
  L.set AS Set,
  L.weight AS Weight,
  L.reps AS Reps
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("{name}") AND L.set
SORT file.name DESC, L.set ASC
LIMIT 10
```

## Notes

```dataview
TABLE WITHOUT ID
  file.link AS Workout,
  L.notes AS Notes
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("{name}") AND L.notes
SORT file.name DESC
```
"""


def generate_dashboard_section(name, ex_type):
    """Generate a dashboard section for a new exercise."""
    if ex_type == "duration":
        return f"""
## {name}

```dataview
LIST WITHOUT ID "**PB:** " + max(rows.L.duration) + "s"
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("{name}") AND L.duration
GROUP BY true
```

```dataview
TABLE WITHOUT ID
  file.link AS Workout,
  L.duration AS "Duration (s)"
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("{name}") AND L.duration
SORT file.name DESC
LIMIT 10
```"""
    else:
        return f"""
## {name}

```dataview
LIST WITHOUT ID "**PB:** " + max(rows.L.weight) + "kg"
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("{name}") AND L.set
GROUP BY true
```

```dataview
TABLE WITHOUT ID
  file.link AS Workout,
  L.set AS Set,
  L.weight AS Weight,
  L.reps AS Reps
FROM "Area/Fitness/Workouts"
FLATTEN file.lists AS L
WHERE L.exercise = link("{name}") AND L.set
SORT file.name DESC, L.set ASC
LIMIT 10
```"""


def get_dashboard_exercises(dashboard_text):
    """Extract exercise names that already have dashboard sections."""
    return set(re.findall(r'^## (.+)$', dashboard_text, re.MULTILINE))


def main():
    signal.signal(signal.SIGINT, signal_handler)

    parser = argparse.ArgumentParser(
        description="Generate Obsidian fitness files from parsed workout JSON.",
    )
    parser.add_argument("--vault-path", default=DEFAULT_VAULT, help="Path to Obsidian vault")
    parser.add_argument("--workout-name", help="Override workout name (default: use suggested_name from JSON)")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without writing files")
    args = parser.parse_args()

    vault = Path(args.vault_path)
    data = json.load(sys.stdin)

    date = data["date"]
    exercises = data["exercises"]
    workout_name = args.workout_name or data.get("suggested_name", "Workout")

    # Paths
    workouts_dir = vault / "Area" / "Fitness" / "Workouts"
    exercises_dir = vault / "Area" / "Fitness" / "Exercises"
    dashboard_path = vault / "Area" / "Fitness" / "Fitness Dashboard.md"

    # --- Step 1: Create workout file ---
    workout_path = workouts_dir / f"{date}.md"
    if workout_path.exists():
        print(f"{Colors.RED}Error: workout file already exists: {workout_path}{Colors.RESET}", file=sys.stderr)
        sys.exit(1)

    workout_content = generate_workout_content(data, workout_name)

    if args.dry_run:
        print(f"{Colors.CYAN}[DRY RUN] Would create: {workout_path.name}{Colors.RESET}")
        print(workout_content)
    else:
        workout_path.write_text(workout_content, encoding="utf-8")
        print(f"{Colors.GREEN}Created: {workout_path.name}{Colors.RESET}")

    # --- Step 2: Create missing exercise files ---
    new_exercises = []
    for ex in exercises:
        ex_name = ex["name"]
        ex_type = ex.get("type", "strength")
        ex_path = exercises_dir / f"{ex_name}.md"

        if ex_path.exists():
            continue

        content = generate_exercise_content(ex_name, ex_type)
        new_exercises.append(ex_name)

        if args.dry_run:
            print(f"{Colors.CYAN}[DRY RUN] Would create exercise: {ex_name}.md{Colors.RESET}")
        else:
            ex_path.write_text(content, encoding="utf-8")
            print(f"{Colors.GREEN}Created exercise: {ex_name}.md{Colors.RESET}")

    # --- Step 3: Update dashboard ---
    new_dashboard_sections = []
    if dashboard_path.exists():
        dashboard_text = dashboard_path.read_text(encoding="utf-8")
        existing_sections = get_dashboard_exercises(dashboard_text)

        sections_to_add = []
        for ex in exercises:
            ex_name = ex["name"]
            ex_type = ex.get("type", "strength")
            if ex_name not in existing_sections:
                section = generate_dashboard_section(ex_name, ex_type)
                sections_to_add.append(section)
                new_dashboard_sections.append(ex_name)

        if sections_to_add:
            # Append new sections at end of dashboard
            updated = dashboard_text.rstrip() + "\n" + "\n".join(sections_to_add) + "\n"

            if args.dry_run:
                print(f"{Colors.CYAN}[DRY RUN] Would add dashboard sections: {new_dashboard_sections}{Colors.RESET}")
            else:
                dashboard_path.write_text(updated, encoding="utf-8")
                print(f"{Colors.GREEN}Dashboard updated: added {new_dashboard_sections}{Colors.RESET}")

    # --- Summary ---
    total_sets = sum(len(ex.get("sets", [])) for ex in exercises)
    total_duration = sum(1 for ex in exercises if "duration" in ex)
    print(f"\n{Colors.BOLD}Processed: {date} ({workout_name}){Colors.RESET}")
    print(f"  {len(exercises)} exercises, {total_sets} sets, {total_duration} duration entries")
    print(f"  New exercise notes: {new_exercises or 'none'}")
    print(f"  Dashboard sections added: {new_dashboard_sections or 'none'}")


if __name__ == "__main__":
    main()
