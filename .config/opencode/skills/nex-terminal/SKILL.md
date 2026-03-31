---
name: nex-terminal
description: "Manages Nex terminal panes, workspaces, events, and file opening via the nex CLI. Use when asked to split panes, create terminal tabs, send commands to other panes, open files in Nex, create workspaces, or manage terminal layout."
---

# Nex Terminal Manager

Manages the Nex terminal multiplexer via the `nex` CLI (`/Applications/Nex.app`).

## Commands

### Panes

**Split current pane:**
```bash
nex pane split --direction horizontal|vertical [--path /dir] [--name <label>]
```

**Create a new pane (tab):**
```bash
nex pane create [--path /dir] [--name <label>]
```

**Close current pane:**
```bash
nex pane close
```

**Rename current pane:**
```bash
nex pane name <name>
```

**Send a command to another pane by name or UUID:**
```bash
nex pane send --to <name-or-uuid> <command...>
```

### Workspaces

**Create a workspace:**
```bash
nex workspace create [--name "Workspace Name"] [--path /dir] [--color blue]
```

### Events

Signal lifecycle or notification events:

```bash
nex event start [--message "..."]
nex event stop [--message "..."]
nex event error [--message "..." --title "..." --body "..."]
nex event notification [--title "..." --body "..."]
nex event session-start [--message "..."]
```

### Open Files

Open a file in the Nex editor/viewer:

```bash
nex open <filepath>
```

## Usage Patterns

**Set up a dev workspace with split panes:**
```bash
nex workspace create --name "Dev" --path ~/dev/project --color green
nex pane name "editor"
nex pane split --direction horizontal --name "server"
nex pane send --to "server" "npm run dev"
```

**Run a command in a named pane:**
```bash
nex pane send --to "tests" "npm test"
```

**Signal task completion:**
```bash
nex event stop --message "Build complete"
nex event notification --title "Done" --body "Deployment finished"
```
