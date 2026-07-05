# Linear CLI Reference (fallback)

Use only when the Linear MCP tools are unavailable. See SKILL.md for when to fall back.

```bash
# Install and auth (once)
npm install -g @linear/cli   # or: brew install linear
linear auth login

# Create
linear issue create --team <TEAM> -t "<TITLE>" -d "<DESCRIPTION>"

# Spike with label, long description via file (avoids shell escaping)
linear issue create --team ENG -t "[2 day spike] Investigate slow checkout" -l "spike" --description-file spike.md
```

Non-obvious flags worth knowing:

- `-p, --parent <TEAM-NUMBER>`: parent issue, e.g. `CUSM-42`.
- `-l, --label <LABEL>`: repeatable.
- `-a, --assignee <self|username>`, `--priority <1-4>` (1=urgent), `--estimate <POINTS>`.
- `--description-file <PATH>`: read description from file; bypasses shell quoting issues with `@`, backticks, newlines.
- `--no-interactive`: skip prompts for scripted use.

Run `linear issue create --help` for the full flag list.
