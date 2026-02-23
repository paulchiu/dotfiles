---
name: linear-create
description: Create Linear issues with team, title, description, and optional fields using the Linear CLI
---

# Linear Create Skill

Create Linear issues using the linear CLI. This skill guides you through the process of creating well-formatted issues in Linear.

## Prerequisites

Ensure `linear` CLI is installed and authenticated:

- Install: `npm install -g @linear/cli` or `brew install linear`
- Authenticate: `linear auth login`

## Usage

When asked to create a Linear issue:

1. Determine the team, title, and description from the user's request
2. Use the linear CLI to create the issue
3. Return the created issue URL to the user

Basic command structure:
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
- **Escaping `@` mentions**: Linear parses `@` as a mention trigger. When writing package names like `@mr-yum/foo` in titles or descriptions, always wrap them in backtick code escapes (`` ` ``) AND add a space after the `@` symbol — e.g., write `` `@ mr-yum/foo` `` instead of `@mr-yum/foo`. This prevents Linear from swallowing the text as an unresolved mention.
