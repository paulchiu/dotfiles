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
| `-p, --parent <ISSUE>` | Parent issue as team_number code (e.g., CUSM-42) |
| `-a, --assignee <ASSIGNEE>` | Assign to 'self' or username/name |
| `--priority <1-4>` | Priority (1=urgent, 4=low) |
| `--estimate <POINTS>` | Story points estimate |
| `-l, --label <LABEL>` | Add labels (can repeat) |
| `--project <PROJECT>` | Associate with project |
| `-s, --state <STATE>` | Workflow state |
| `--due-date <DATE>` | Due date |
| `--start` | Start the issue immediately |
| `--no-interactive` | Skip interactive prompts |

## Issue Relationships

When users mention "parent", "blocked by", or "sub-issue", these refer to actual Linear linked issues, not just description text. The CLI supports the following:

| Relationship | CLI Support | How to Set |
|--------------|-------------|------------|
| **Parent** | ✅ Supported | Use `-p <ISSUE>` flag during creation or `linear issue update <ID> -p <ISSUE>` |
| **Sub-issue** | ✅ Automatic | Create issue with `-p <PARENT>` to make it a sub-issue |
| **Blocked by** | ❌ Not supported | Must use Linear web UI or API |
| **Depends on** | ❌ Not supported | Must use Linear web UI or API |

**Note**: Only parent relationships can be set via CLI. For "blocked by" or other dependencies, instruct the user to set these manually in the Linear web interface, or add them as reference links in the description.

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

### Creating a sub-issue (with parent)

```bash
linear issue create --team CUSM -t "Fix SMS bug" -d "Bug details here" -p CUSM-42
```

This creates CUSM-xxx as a sub-issue of CUSM-42.

## Workflow

1. Check which teams exist: `linear team list`
2. Create the issue with appropriate team and details
3. Linear CLI returns the created issue URL

## Tips

- Use `--no-interactive` for scripts/automation
- Descriptions support full markdown formatting
- Team identifiers are usually uppercase (CAD, ENG, PROD, etc.)
- You can update an issue later with: `linear issue update <ID>`
- **Escaping `@` mentions**: Linear parses `@` as a mention trigger and shells may interpret it as command substitution. When writing package names like `@mr-yum/foo`:
  - In titles/descriptions: Wrap in backticks `` `@mr-yum/foo` `` or use single quotes around the entire argument
  - In shell commands: Use single quotes around the entire title/description string to prevent shell interpretation (e.g., `-t 'Update @mr-yum/sms'`)
  - Alternatively, use the `--description-file` flag to read from a file instead of passing markdown directly on the command line
