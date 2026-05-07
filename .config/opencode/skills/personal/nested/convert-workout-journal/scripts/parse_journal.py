#!/usr/bin/env python3
"""
Parse raw workout journal notes into structured JSON.

Reads an Obsidian journal file (Area/Journal/YYYY-MM-DD.md) and extracts
exercises, sets, notes, and durations into a deterministic JSON structure.

Supports:
  - Strength exercises: [[Name]] heading + numbered sets (N. weight x reps)
  - Duration exercises: [[container]] heading + dash-prefixed sub-items (- Name: Xmin Ys)
  - Inline notes: parenthetical text in set lines → set-level notes
  - Multi-line notes: free text between heading and sets → joined with ". "
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


def load_exercises(script_dir):
    """Load canonical exercise registry."""
    exercises_path = script_dir / "exercises.json"
    with open(exercises_path, "r", encoding="utf-8") as f:
        return json.load(f)


def build_alias_map(exercises):
    """Build lowercase alias → canonical name mapping."""
    alias_map = {}
    for canonical, info in exercises.items():
        alias_map[canonical.lower()] = canonical
        for alias in info.get("aliases", []):
            alias_map[alias.lower()] = canonical
    return alias_map


def resolve_exercise(raw_name, alias_map, exercises_dir):
    """Resolve a raw exercise name to its canonical form.

    Returns (canonical_name, exercise_type, warning_or_None).
    """
    lower = raw_name.strip().lower()

    # Try alias map first
    if lower in alias_map:
        canonical = alias_map[lower]
        warning = None
        if raw_name.strip() != canonical:
            warning = f"Exercise name resolved: '{raw_name.strip()}' -> '{canonical}'"
        return canonical, None, warning

    # Fallback: case-insensitive match against exercise filenames
    if exercises_dir.exists():
        for f in exercises_dir.iterdir():
            if f.suffix == ".md" and f.stem.lower() == lower:
                return f.stem, None, f"Exercise name case-corrected: '{raw_name.strip()}' -> '{f.stem}'"

    # Unresolved: title-case the raw name
    title_cased = raw_name.strip().title()
    return title_cased, None, f"Unknown exercise: '{raw_name.strip()}' (using '{title_cased}')"


def parse_weight(raw):
    """Parse weight string, stripping kg suffix. Returns float or int."""
    cleaned = re.sub(r'\s*kg\s*$', '', raw.strip(), flags=re.IGNORECASE)
    val = float(cleaned)
    return int(val) if val == int(val) else val


def parse_duration_seconds(minutes_str, seconds_str=None):
    """Convert minutes + optional seconds to total seconds."""
    total = int(minutes_str) * 60
    if seconds_str:
        total += int(seconds_str)
    return total


def parse_simple_duration_seconds(raw):
    """Parse a bare duration value like M:SS, Xmin Ys, or Xs."""
    mmss = re.match(r'^\s*(\d+):(\d{2})\s*$', raw)
    if mmss:
        return parse_duration_seconds(mmss.group(1), mmss.group(2))

    verbose = re.match(r'^\s*(\d+)\s*min(?:\s+(\d+)\s*s)?\s*$', raw, re.IGNORECASE)
    if verbose:
        return parse_duration_seconds(verbose.group(1), verbose.group(2))

    bare_seconds = re.match(r'^\s*(\d+)\s*s\s*$', raw, re.IGNORECASE)
    if bare_seconds:
        return int(bare_seconds.group(1))

    return None


def parse_journal(text, date, alias_map, exercises, exercises_dir):
    """Parse raw journal text into structured workout data."""
    lines = text.split("\n")
    result = {
        "date": date,
        "suggested_name": None,
        "exercises": [],
        "unparsed_lines": [],
        "warnings": [],
    }

    # Regex patterns
    heading_re = re.compile(r'^\s*(?:##\s*)?\[\[(.+?)\]\]\s*$')
    set_re = re.compile(r'^\s*(\d+)\.\s*([\d.]+)\s*(?:kg)?\s*(?:\(([^)]+)\))?\s*[xX]\s*(\d+)\s*$')
    duration_re = re.compile(r'^\s*-\s*(.+?):\s*(\d+)\s*min(?:\s+(\d+)\s*s)?\s*$')

    # Split into blocks: pre-workout lines + exercise blocks
    blocks = []
    current_heading = None
    current_lines = []
    pre_workout = []

    for line in lines:
        m = heading_re.match(line)
        if m:
            if current_heading is not None:
                blocks.append((current_heading, current_lines))
            elif current_lines:
                pre_workout = current_lines
            current_heading = m.group(1)
            current_lines = []
        else:
            current_lines.append(line)

    # Flush last block
    if current_heading is not None:
        blocks.append((current_heading, current_lines))
    elif current_lines:
        pre_workout = current_lines

    # Collect unparsed pre-workout lines (skip blanks)
    for line in pre_workout:
        stripped = line.strip()
        if stripped:
            result["unparsed_lines"].append(stripped)

    # Process each exercise block
    for raw_heading, block_lines in blocks:
        canonical, ex_type_hint, warning = resolve_exercise(raw_heading, alias_map, exercises_dir)
        if warning:
            result["warnings"].append(warning)

        # Look up type from registry
        ex_info = exercises.get(canonical, {})
        ex_type = ex_type_hint or ex_info.get("type")

        # Try parsing block content
        sets = []
        notes = []
        duration_exercises = []
        direct_duration = None

        for line in block_lines:
            stripped = line.strip()
            if not stripped:
                continue

            # Try set pattern
            sm = set_re.match(stripped)
            if sm:
                set_data = {
                    "set": int(sm.group(1)),
                    "weight": parse_weight(sm.group(2)),
                    "reps": int(sm.group(4)),
                }
                if sm.group(3):
                    set_data["notes"] = sm.group(3).strip()
                sets.append(set_data)
                continue

            # Try duration pattern
            dm = duration_re.match(stripped)
            if dm:
                sub_name = dm.group(1).strip()
                seconds = parse_duration_seconds(dm.group(2), dm.group(3))
                sub_canonical, _, sub_warning = resolve_exercise(sub_name, alias_map, exercises_dir)
                if sub_warning:
                    result["warnings"].append(sub_warning)
                sub_info = exercises.get(sub_canonical, {})
                duration_exercises.append({
                    "name": sub_canonical,
                    "type": sub_info.get("type", "duration"),
                    "notes": [],
                    "duration": seconds,
                })
                continue

            # Try a direct duration value beneath a duration exercise heading
            if ex_type == "duration":
                seconds = parse_simple_duration_seconds(stripped)
                if seconds is not None:
                    direct_duration = seconds
                    continue

            # Otherwise it's a note line
            notes.append(stripped)

        # If we got duration sub-exercises (container heading pattern)
        if duration_exercises:
            result["exercises"].extend(duration_exercises)
        elif direct_duration is not None:
            result["exercises"].append({
                "name": canonical,
                "type": "duration",
                "notes": notes,
                "duration": direct_duration,
            })
        elif sets:
            exercise = {
                "name": canonical,
                "type": ex_type or "strength",
                "notes": notes,
                "sets": sets,
            }
            result["exercises"].append(exercise)
        elif notes and not sets and not duration_exercises:
            # Heading with only notes, no sets — might be notes-only exercise block
            # (e.g. machine row with settings but user forgot to log sets)
            exercise = {
                "name": canonical,
                "type": ex_type or "strength",
                "notes": notes,
                "sets": [],
            }
            result["exercises"].append(exercise)
            result["warnings"].append(f"Exercise '{canonical}' has notes but no sets")

    # Auto-suggest workout name
    if result["exercises"]:
        all_duration = all(
            e.get("type") == "duration" or "duration" in e
            for e in result["exercises"]
        )
        if all_duration:
            result["suggested_name"] = "Nightly Stretch"
        else:
            first = result["exercises"][0]["name"]
            result["suggested_name"] = f"{first} Day"

    return result


def main():
    signal.signal(signal.SIGINT, signal_handler)

    parser = argparse.ArgumentParser(
        description="Parse workout journal notes into structured JSON.",
    )
    parser.add_argument("--file", help="Path to journal file")
    parser.add_argument("--date", help="Date in YYYY-MM-DD format (resolves to Area/Journal/YYYY-MM-DD.md)")
    parser.add_argument("--vault-path", default=DEFAULT_VAULT, help="Path to Obsidian vault")
    args = parser.parse_args()

    vault = Path(args.vault_path)
    script_dir = Path(__file__).parent
    exercises = load_exercises(script_dir)
    alias_map = build_alias_map(exercises)
    exercises_dir = vault / "Area" / "Fitness" / "Exercises"

    # Resolve file path
    if args.file:
        file_path = Path(args.file)
    elif args.date:
        if not re.match(r'^\d{4}-\d{2}-\d{2}$', args.date):
            print("Error: --date must be YYYY-MM-DD format", file=sys.stderr)
            sys.exit(1)
        file_path = vault / "Area" / "Journal" / f"{args.date}.md"
    else:
        print("Error: provide --file or --date", file=sys.stderr)
        sys.exit(1)

    if not file_path.exists():
        print(f"Error: file not found: {file_path}", file=sys.stderr)
        sys.exit(1)

    # Extract date from filename if not provided
    date = args.date
    if not date:
        m = re.search(r'(\d{4}-\d{2}-\d{2})', file_path.stem)
        if m:
            date = m.group(1)
        else:
            print("Error: cannot infer date from filename, use --date", file=sys.stderr)
            sys.exit(1)

    text = file_path.read_text(encoding="utf-8")
    result = parse_journal(text, date, alias_map, exercises, exercises_dir)

    # Print warnings to stderr
    for w in result["warnings"]:
        print(f"{Colors.YELLOW}Warning: {w}{Colors.RESET}", file=sys.stderr)
    if result["unparsed_lines"]:
        print(f"{Colors.CYAN}Unparsed lines: {result['unparsed_lines']}{Colors.RESET}", file=sys.stderr)

    # Output JSON to stdout
    json.dump(result, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
