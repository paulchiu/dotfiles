---
name: pup-datadog
description: Query Datadog metrics, logs, monitors, traces, and 30+ API domains via the pup CLI. Use when working with Datadog observability data - searching logs, querying metrics, checking monitor status, investigating APM traces, analyzing security signals, auditing cloud costs, or any Datadog API interaction. Supports OAuth2 and API key authentication.
---

# Datadog (Pup CLI)

## Overview

The pup CLI provides comprehensive access to Datadog's API for querying metrics, logs, monitors, traces, security signals, and 30+ other API domains. It supports both OAuth2 and API key authentication.

## Agent Mode (Auto-Detected)

Pup **automatically detects AI coding agents** (including Claude Code, Codex, OpenCode, Cursor, and others) and enables **agent mode** with these benefits:

- **No confirmation prompts** - Commands auto-approve without interactive input
- **Structured JSON output** - All responses wrapped in metadata envelopes with `status`, `data`, and `metadata` fields
- **Enhanced error messages** - JSON errors include `error_code`, `error_message`, and `suggestions` for remediation
- **Schema discovery** - `pup --help` returns structured JSON schema instead of text

Agent mode is triggered automatically via environment variables (`CLAUDE_CODE=1`, `OPENCODE=1`, `CODEX=1`, etc.) or explicitly with `pup --agent` flag.

See [references/llm-guide.md](references/llm-guide.md) for complete LLM agent documentation.

## Quick Start

### Authentication

**OAuth2 (Recommended for interactive use):**
```bash
pup auth login
```

**API Keys (for automation):**
```bash
export DD_API_KEY="your-api-key"
export DD_APP_KEY="your-app-key"
export DD_SITE="datadoghq.com"  # or datadoghq.eu, etc.
```

### Common Workflows

**1. Investigate Errors**
```bash
# Search recent error logs
pup logs search --query="status:error" --from=1h --limit=20

# Aggregate errors by service
pup logs aggregate --query="status:error" --from=1h --compute="count" --group-by="service"

# Check production monitors
pup monitors list --tags="env:production" --limit=50
```

**2. Performance Investigation**
```bash
# Query service latency metrics
pup metrics query --query="avg:trace.servlet.request.duration{env:prod} by {service}" --from=1h

# Find slow traces (durations in NANOSECONDS!)
pup apm traces search --query="@duration:>5000000000" --from=1h --limit=20

# List APM services
pup apm services list
```

**3. Security Audit**
```bash
# Search audit logs
pup audit-logs search --query="*" --from=1d --limit=100

# List security rules
pup security rules list

# Critical security signals
pup security signals list --query="status:critical" --from=1d
```

## Query Syntax Reference

See [references/query-syntax.md](references/query-syntax.md) for detailed query syntax for logs, metrics, APM, monitors, and other Datadog data types.

## Time Formats

- Relative: `5s`, `30m`, `1h`, `4h`, `1d`, `7d`, `1w`, `30d`
- Absolute: Unix timestamp (ms) or RFC3339 (`2024-01-01T00:00:00Z`)
- Examples: `--from=1h`, `--from=30m --to=now`, `--from="5 minutes"`

## Best Practices

1. **Always specify `--from`** to set explicit time ranges
2. **Start narrow, then widen** - begin with 1h ranges for faster results
3. **Filter by service first** when investigating issues
4. **Use `--limit`** to control result size (defaults vary: 50-200)
5. **APM durations are in NANOSECONDS** - 1 second = 1000000000
6. **Use `pup logs aggregate`** for counts instead of fetching all logs
7. **Prefer JSON output** (default) for parsing; use `--output=table` for human display

## Anti-Patterns to Avoid

- Don't omit `--from` on time-series queries
- Don't use `--limit=1000` as a first step; start small
- Don't fetch raw logs just to count them - use aggregate
- Don't assume APM durations are in seconds/milliseconds (they're nanoseconds!)
- Don't retry failed requests without checking the error code
- Don't pipe large JSON through multiple jq transforms

## Command Categories

### Core Observability
- `pup logs search|aggregate` - Query and aggregate logs
- `pup metrics query` - Query time-series metrics
- `pup monitors list|search|get` - Manage monitors
- `pup apm services|traces|dependencies` - APM data

### Security & Compliance
- `pup security signals|rules` - Security monitoring
- `pup audit-logs search` - Audit trail queries
- `pup compliance` - Compliance frameworks

### Infrastructure & Cloud
- `pup cloud aws|azure|gcp` - Cloud integrations
- `pup hosts list` - Infrastructure monitoring
- `pup containers` - Container observability

### Platform & Management
- `pup dashboards` - Dashboard management
- `pup slos` - Service Level Objectives
- `pup incidents` - Incident management
- `pup cases` - Case management
- `pup notebooks` - Notebooks and documentation

### CI/CD & Developer Experience
- `pup cicd pipelines|tests|events` - CI/CD visibility
- `pup code-coverage` - Test coverage data
- `pup software` - Software catalog and SBOM

### Cost & Usage
- `pup cost attribution|by-org|projected` - Cost analysis
- `pup usage` - API and feature usage

## Global Flags

- `--agent` - Enable agent mode (auto-detected for AI assistants)
- `--org <name>` - Use named org session for multi-org
- `--output json|table|yaml` - Output format (default: json)
- `--yes` - Skip confirmation prompts

## Multi-Organization Support

```bash
# Login to specific org
pup auth login --org=production

# Switch between orgs
pup monitors list --org=production
pup logs search --query="status:error" --org=staging

# List all sessions
pup auth list
```

## Getting Help

```bash
pup --help                    # Overview and all commands
pup logs --help               # Specific command help
pup logs search --help        # Subcommand help
```

## Reference Documentation

For detailed information about specific command categories, see:
- [references/query-syntax.md](references/query-syntax.md) - Query syntax for all data types
- [references/workflows.md](references/workflows.md) - Common investigation workflows
- [references/llm-guide.md](references/llm-guide.md) - LLM agent features, agent mode, and structured output
