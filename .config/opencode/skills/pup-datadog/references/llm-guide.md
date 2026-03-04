# LLM Agent Guide for Pup CLI

This guide covers the agent operability system, discovery commands, and LLM-specific features of the pup CLI.

## Agent Mode

Pup **auto-detects AI coding agents** and switches to agent mode automatically. Detection methods:

### Auto-Detection Environment Variables

- `CLAUDECODE=1`, `CLAUDE_CODE=1`
- `CURSOR_AGENT=1`
- `CODEX=1`, `OPENAI_CODEX=1`
- `OPENCODE=1`
- `AIDER=1`
- `CLINE=1`
- `WINDSURF_AGENT=1`
- `GITHUB_COPILOT=1`
- `AMAZON_Q=1`, `AWS_Q_DEVELOPER=1`
- `GEMINI_CODE_ASSIST=1`
- `SRC_CODY=1`
- `AGENT=1`

### Explicit Activation

```bash
# Force agent mode
pup --agent <command>

# Environment override
FORCE_AGENT_MODE=1 pup <command>
```

### What Changes in Agent Mode

| Behavior | Human Mode | Agent Mode |
|----------|-----------|------------|
| `--help` output | Standard text help | **Structured JSON schema** |
| Confirmation prompts | Interactive stdin | **Auto-approved** (no hangs) |
| Error format | Human text with suggestions | **Structured JSON** with error codes |
| API responses | Raw API response | **Envelope with metadata** (count, truncation, warnings) |

### Verifying Agent Mode

```bash
# Returns JSON schema (not text) when agent is detected
pup --help

# Force agent mode for testing
FORCE_AGENT_MODE=1 pup --help

# Subtree schema (specific domain)
FORCE_AGENT_MODE=1 pup logs --help
```

## Discovery Commands

### 1. Full Command Schema

In agent mode, `--help` returns the complete JSON schema:

```bash
pup --help
# Returns: { version, auth, global_flags, commands[], query_syntax, time_formats, workflows, best_practices, anti_patterns }
```

### 2. Domain-Specific Schema

```bash
pup logs --help      # Only logs commands + logs query syntax
pup monitors --help  # Only monitors commands
pup metrics --help   # Only metrics commands
pup apm --help       # Only APM commands
```

### 3. Explicit Schema Commands

These work regardless of agent mode:

```bash
pup agent schema              # Full JSON schema
pup agent schema --compact    # Minimal schema (names + flags only)
pup agent guide               # Full steering guide (markdown)
pup agent guide logs          # Domain-specific guide section
```

## Agent Envelope (Agent Mode Output)

In agent mode, all command output is wrapped in a metadata envelope:

### Success Response

```json
{
  "status": "success",
  "data": [ ... ],
  "metadata": {
    "count": 42,
    "truncated": false,
    "command": "monitors list",
    "warnings": []
  }
}
```

### Error Response

```json
{
  "status": "error",
  "error_code": 401,
  "error_message": "Authentication failed",
  "operation": "list monitors",
  "suggestions": [
    "Run 'pup auth login' to re-authenticate",
    "Or set DD_API_KEY and DD_APP_KEY environment variables"
  ]
}
```

## Error Reference

| Status | Meaning | Suggested Action |
|--------|---------|------------------|
| 401 | Authentication failed | `pup auth login` or check DD_API_KEY/DD_APP_KEY |
| 403 | Insufficient permissions | Verify API/App key scopes |
| 404 | Resource not found | Check the resource ID |
| 429 | Rate limited | Wait and retry with backoff |
| 5xx | Server error | Retry after delay; check status.datadoghq.com |

## Key Best Practices (Agent Mode)

1. **Always specify `--from`** — most commands default to 1h but be explicit
2. **Start narrow, widen later** — begin with 1h, expand only if needed
3. **Filter at the API level** — use `--tags`, `--query`, `--name` instead of local parsing
4. **Use `aggregate` for counts** — don't fetch all logs and count them yourself
5. **APM durations are in NANOSECONDS** — 1s = 1,000,000,000
6. **Use `--yes` for automation** — or rely on agent mode auto-approval
7. **Check `pup agent schema`** when unsure about flags
8. **Chain queries** — aggregate first to find patterns, then search for specifics

## Anti-Patterns to Avoid

1. **Don't omit `--from`** on time-series queries — unexpected ranges or errors
2. **Don't use `--limit=1000` as a first step** — start small and refine
3. **Don't list all monitors without filters** in large orgs (>10k monitors)
4. **Don't assume durations are in seconds** — APM uses nanoseconds
5. **Don't fetch raw logs to count them** — use `pup logs aggregate --compute=count`
6. **Don't retry 401/403 errors** — re-authenticate or check permissions instead
7. **Don't use `--from=30d`** unless you specifically need a month of data

## Architecture Notes

### Agent Detection
- Implementation: `src/useragent.rs`
- Table-driven detector registry
- `is_agent_mode()` checks `FORCE_AGENT_MODE` first, then agent env vars

### Schema Generation
- Implementation: `src/commands/agent.rs`
- Walks the clap command tree automatically
- Stays in sync as commands are added

### Output Envelope
- Implementation: `src/formatter.rs`
- Wraps responses with metadata
- Structured error formatting for agent consumption

## Using with This Skill

This skill automatically benefits from pup's agent mode detection. When you invoke pup commands through this skill:

1. **Agent mode is auto-detected** via environment variables
2. **No confirmation prompts** will block execution
3. **Structured JSON output** makes parsing easier
4. **Error responses include suggestions** for remediation

### Example Agent Mode Commands

```bash
# Get full schema (returns JSON)
pup --help

# Get specific command help (returns JSON)
pup logs search --help

# Run command with agent envelope output
pup logs search --query="status:error" --from=1h --limit=10
```

### Handling Agent Mode Output

When parsing pup output in agent mode:

```bash
# Extract data from envelope
pup logs search --query="status:error" --from=1h | jq '.data'

# Get count from metadata
pup logs search --query="status:error" --from=1h | jq '.metadata.count'

# Check for warnings
pup logs search --query="status:error" --from=1h | jq '.metadata.warnings'
```
