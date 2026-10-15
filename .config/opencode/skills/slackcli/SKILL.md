---
name: slackcli
description: "slackcli for Slack reads the Slack MCP lacks: saved/Later list, unread, drafts, canvas listing, files, user groups."
---

# slackcli

Prefer the Slack MCP (`mcp__claude_ai_Slack__*`) for search, reading channels and threads, user profiles, and reading a canvas by ID. Use `slackcli` only for the gaps below. Written against v0.15.0 (`/opt/homebrew/bin/slackcli`); the installed binary's `slackcli <group> <cmd> --help` is the source of truth.

## Safety

slackcli runs as Paul through his browser session. Never send, edit, delete, react, schedule, mark read, join, leave, or change members or user groups unless Paul explicitly asks in this run (same rule as slack-copilot). Reads are fine.

## Health check

```bash
slackcli auth whoami --json   # status: ok | auth_failed | unreachable
```

On `auth_failed`, stop and tell Paul to re-run `slackcli auth login-auto` himself. Do not attempt login. Default workspace is me&u (Enterprise Grid `E0677T2NM2R`, browser auth); pass `--workspace <id|name>` for another.

## Gap commands

Always pass `--json` for machine use; add `--fields a,b.c` to trim output. Errors exit 1 with a JSON error object on the last stderr line.

```bash
# Saved for Later list: { item_count, items: [{ type, channel_id, channel_name, message, date_saved, todo_state }] }
slackcli saved list --json [--limit N] [--state saved|to_do|completed]

# Unread conversations, mentions first; --messages also returns the unread messages and thread replies (does not mark read)
slackcli conversations unread --json [--types channels,dms,groups] [--messages] [--max-conversations N] [--limit N]

# Your unsent drafts: { draft_count, drafts: [{ draft_id, channel_id, text, date_created, thread_ts? }] }
slackcli messages list-drafts --json [--limit N]

# Canvas listing, and a channel's attached canvas as Markdown
slackcli canvas list --json [--channel <id|url|name>] [--limit N]
slackcli canvas read --channel <id|url|name> --json

# Files: metadata, textual content, or raw bytes (never overwrites; --yes needed for a path outside cwd when non-interactive)
slackcli files info <file-id-or-url> --json
slackcli files read <file-id-or-url> --json [--raw]
slackcli files download <file-id-or-url> --output <path> [--yes]

# User groups and their members
slackcli usergroups list --json [--include-disabled]
slackcli usergroups read <S-id|@handle|"exact name"> --json
```

Saved items carry `message.ts` and `channel_id` but no permalink: build one as `https://meandu.enterprise.slack.com/archives/<channel_id>/p<ts without the dot>`.

`messages list-scheduled` is app-token only and fails with Paul's browser auth; there is no way to list scheduled messages here.
