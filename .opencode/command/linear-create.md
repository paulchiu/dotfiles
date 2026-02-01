---
description: Create Linear issue with team, title, description, and optional fields
---

Create a Linear issue using the linear CLI. This command guides you through the process of creating well-formatted issues in Linear.

## Prerequisites

Ensure `linear` CLI is installed and authenticated:

- Install: `npm install -g @linear/cli` or `brew install linear`
- Authenticate: `linear auth login`

## Usage

```bash
linear issue create --team <TEAM> -t "<TITLE>" -d "<DESCRIPTION>"
```

## Available Options

| Flag | Description |
|------|-------------|
| `--team <TEAM>` | Target team (e.g., CAD, ENG, PROD) |
| `-t, --title <TITLE>` | Issue title (required) |
| `-d, --description <DESCRIPTION>` | Issue description (supports markdown) |
| `-a, --assignee <ASSIGNEE>` | Assign to 'self' or username/name |
| `--priority <1-4>` | Priority (1=urgent, 4=low) |
| `--estimate <POINTS>` | Story points estimate |
| `-l, --label <LABEL>` | Add labels (can repeat) |
| `--project <PROJECT>` | Associate with project |
| `-s, --state <STATE>` | Workflow state |
| `--due-date <DATE>` | Due date |
| `--start` | Start the issue immediately |
| `--no-interactive` | Skip interactive prompts |

## Examples

### Basic issue creation

```bash
linear issue create --team CAD -t "Fix login bug" -d "Users cannot login with SSO"
```

### With assignee and priority

```bash
linear issue create --team ENG -t "Update dependencies" -d "Security patches needed" -a self --priority 2
```

### With labels and project

```bash
linear issue create --team PROD -t "Feature X" -d "New feature description" -l "feature" -l "q1" --project "Roadmap 2024"
```

## Workflow

1. Check which teams exist: `linear team list`
2. Create the issue with appropriate team and details
3. Linear CLI returns the created issue URL

## Tips

- Use `--no-interactive` for scripts/automation
- Descriptions support full markdown formatting
- Team identifiers are usually uppercase (CAD, ENG, PROD, etc.)
- You can update an issue later with: `linear issue update <ID>`
