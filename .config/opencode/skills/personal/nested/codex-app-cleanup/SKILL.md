---
model: haiku
name: codex-app-cleanup
description: "Cleans stale Codex/ChatGPT desktop state: dead project picker entries, invalid env refs, obsolete worktree pairings. Use when the user says Codex still shows old projects or envs, stale worktrees or PR folders appear in the desktop app, or asks to clean up Codex app state or remove invalid local refs from the Codex or ChatGPT desktop app."
---

# Codex App Cleanup

Remove stale local desktop state that points at worktrees or project roots that no longer exist on disk.

Two stores matter:

1. **Codex project picker state**: `~/.codex/.codex-global-state.json`. Relevant keys: `electron-saved-workspace-roots`, `electron-workspace-root-labels`, `active-workspace-roots`, `project-order`. If stale entries appear in the project picker, this file is the primary source of truth.
2. **ChatGPT desktop pairing cache**: `~/Library/Application Support/com.openai.chat/app_pairing_extensions`. Can hold stale pairing records, but cleaning it alone usually does NOT fix the project picker. Only touch it in step 8.

Follow the steps below in order. Do not skip steps. Do not improvise extra cleanup.

## Step 1: Inspect the state file

Run:

```bash
test -f ~/.codex/.codex-global-state.json && echo EXISTS || echo MISSING
```

- If output is `MISSING`: stop. Report that `~/.codex/.codex-global-state.json` does not exist and that there is no picker state to clean.
- If output is `EXISTS`: read the file with the Read tool at path `~/.codex/.codex-global-state.json` (expand to the absolute path, e.g. `/Users/paul/.codex/.codex-global-state.json`).

Note: some values in this file may be JSON encoded as strings (a list stored inside a string). That is normal. The prune script in step 6 handles both forms.

If the user named specific stale entries (project names, branch names, worktree folders), search the file content for those names first and note which keys contain them.

## Step 2: Find stale paths

Extract every path listed under `electron-saved-workspace-roots` (and any paths in `active-workspace-roots` and `project-order` not already covered). For each path, run:

```bash
test -d "<path>" && echo "KEEP <path>" || echo "STALE <path>"
```

Rules:

- A path is stale ONLY if `test -d` says it does not exist. Never mark a path stale because it looks like a PR worktree or an old branch. If the directory exists, keep it.
- Collect the exact list of STALE paths. This list drives everything after this point.

Branch:

- If the STALE list is empty AND the user did not point at the pairing cache: stop. Report that all saved workspace roots exist on disk and nothing needs pruning, and suggest the pairing cache (step 8) only if the user's symptom is about envs rather than the picker.
- If the STALE list is non-empty: continue to step 3.

## Step 3: Check whether Codex is running

Run:

```bash
pgrep -x Codex || echo NOT_RUNNING
```

- Output is one or more PIDs: Codex is running. Continue to step 4.
- Output is `NOT_RUNNING`: skip to step 5.

## Step 4: Quit Codex fully

The app must not be running while you edit the state file, otherwise it will overwrite your changes on quit.

Run:

```bash
osascript -e 'quit app "Codex"'
sleep 3
pgrep -x Codex || echo NOT_RUNNING
```

- If the final output is `NOT_RUNNING`: continue to step 5.
- If PIDs still appear: run the three commands once more. If PIDs STILL appear after the second attempt, stop and report: Codex will not quit, ask the user to quit it manually, and do not edit the file.

## Step 5: Back up the state file

Run:

```bash
cp ~/.codex/.codex-global-state.json ~/.codex/.codex-global-state.json.bak.$(date +%Y%m%d-%H%M%S)
ls ~/.codex/.codex-global-state.json.bak.* | tail -1
```

Record the printed backup path; you must include it in your final report. If the `cp` fails, stop and report the error. Do not edit the file without a backup.

## Step 6: Prune the stale paths

Run the following, replacing `"<stale1>" "<stale2>"` with every path from your STALE list (each as its own quoted argument):

```bash
python3 - "<stale1>" "<stale2>" <<'EOF'
import json, os, sys

state_file = os.path.expanduser("~/.codex/.codex-global-state.json")
stale = set(sys.argv[1:])
if not stale:
    print("ERROR: no stale paths given")
    sys.exit(1)

with open(state_file) as f:
    data = json.load(f)

def decode(v):
    """Some values are JSON encoded inside a string; unwrap if so."""
    if isinstance(v, str):
        try:
            return json.loads(v), True
        except (ValueError, TypeError):
            return v, False
    return v, False

removed = 0

for key in ["electron-saved-workspace-roots", "active-workspace-roots", "project-order"]:
    if key not in data:
        continue
    val, was_str = decode(data[key])
    if isinstance(val, list):
        new = [p for p in val if p not in stale]
        removed += len(val) - len(new)
        data[key] = json.dumps(new) if was_str else new

key = "electron-workspace-root-labels"
if key in data:
    val, was_str = decode(data[key])
    if isinstance(val, dict):
        new = {k: v for k, v in val.items() if k not in stale}
        removed += len(val) - len(new)
        data[key] = json.dumps(new) if was_str else new

with open(state_file, "w") as f:
    json.dump(data, f, indent=2)
print(f"REMOVED {removed} entries")
EOF
```

- Expected output: `REMOVED <n> entries` where `<n>` is greater than 0.
- If the script prints an error or a Python traceback: stop, restore the backup with `cp <backup-path> ~/.codex/.codex-global-state.json`, and report the error.
- If it prints `REMOVED 0 entries`: the stale paths were not found in any key. Report this and re-check the paths against the file content before retrying. Do not guess new paths.

Change ONLY the four keys above. Never delete other keys, and never wipe or recreate the whole file.

## Step 7: Validate and relaunch

Run:

```bash
python3 -m json.tool ~/.codex/.codex-global-state.json > /dev/null && echo VALID_JSON || echo INVALID_JSON
```

- If output is `INVALID_JSON`: stop, restore the backup with `cp <backup-path> ~/.codex/.codex-global-state.json`, and report the failure.
- If output is `VALID_JSON`: re-read the file and confirm every remaining saved workspace root still exists with `test -d "<path>"`. Every remaining path must print as existing. If one does not, report it (do not silently remove more).

Then, only if Codex was running in step 3, relaunch it:

```bash
open -a Codex
```

If Codex was not running before, leave it closed and say so in the report.

If the user only cared about the project picker, you are done. Go to the Final Report. Only continue to step 8 if the user's symptom mentions envs or pairing records, or if the user explicitly asked for pairing cache cleanup.

## Step 8: Pairing cache cleanup (only when asked or picker fix is not enough)

Run:

```bash
ls "$HOME/Library/Application Support/com.openai.chat/app_pairing_extensions"
```

- If the directory does not exist or is empty: report that and stop.
- Otherwise, search the files for the stale names or paths:

```bash
grep -rl "<stale-name-or-path>" "$HOME/Library/Application Support/com.openai.chat/app_pairing_extensions"
```

For each matching file, read it and confirm it points at a local path that no longer exists (`test -d` on the referenced path). Then, for each confirmed-stale file:

1. Back it up: `cp "<file>" "<file>.bak.$(date +%Y%m%d-%H%M%S)"`
2. Delete only that file: `rm "<file>"`

Delete only files whose referenced local path is missing on disk. If a file references a path that still exists, keep it. If you are unsure about a file, keep it and mention it in the report.

## Guardrails

- Never remove a root whose directory still exists.
- Never wipe or recreate the whole global state file to clear a few bad entries.
- Do not treat Codex logs as the source of truth. Historic log lines mention deleted paths long after cleanup; only `test -d` decides staleness.
- If the user only cares about the picker, `.codex-global-state.json` is the fix; pairing caches are secondary.
- Every destructive command must be preceded by its backup step. If any command fails, stop and report the exact error instead of continuing.

## Final Report

Always report, in this order:

1. Which store held the stale entries (`.codex-global-state.json`, the pairing cache, or both).
2. How many invalid refs were removed (use the `REMOVED <n>` output).
3. The backup file path(s).
4. Whether Codex was relaunched, left closed, or still needs relaunching.
