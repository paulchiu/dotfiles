# Datadog Investigation Workflows

Common investigation workflows using the pup CLI.

## 1. Service Outage Investigation

### Step 1: Check Service Health

```bash
# Check if service is reporting
pup apm services list --env=production

# Look at service statistics
pup apm services stats --service=payment-api --env=production --from=1h

# Check dependencies
pup apm dependencies list --env=production --from=1h
```

### Step 2: Analyze Error Patterns

```bash
# Aggregate errors by service
pup logs aggregate \
  --query="status:error" \
  --from=1h \
  --compute="count" \
  --group-by="service"

# Search for recent errors
pup logs search \
  --query="status:error service:payment-api" \
  --from=30m \
  --limit=50 \
  --sort="desc"

# Look for specific error messages
pup logs search \
  --query='status:error "connection refused"' \
  --from=1h \
  --limit=100
```

### Step 3: Check Related Monitors

```bash
# List monitors for the service
pup monitors list \
  --tags="service:payment-api" \
  --limit=50

# Search for alerting monitors
pup monitors search \
  --query="status:Alert" \
  --limit=100

# Get specific monitor details
pup monitors get <monitor-id>
```

### Step 4: Analyze Metrics

```bash
# Request rate
pup metrics query \
  --query="sum:trace.http.request.hits{service:payment-api}" \
  --from=4h

# Error rate
pup metrics query \
  --query="sum:trace.http.request.errors{service:payment-api}" \
  --from=4h

# Latency percentiles
pup metrics query \
  --query="avg:trace.servlet.request.duration{service:payment-api}" \
  --from=4h
```

## 2. Performance Degradation Investigation

### Step 1: Identify Slow Operations

```bash
# Find slow traces (>1 second)
pup apm traces search \
  --query="service:api @duration:>1000000000" \
  --from=1h \
  --limit=50

# Analyze by operation
pup apm services operations \
  --service=api \
  --env=production \
  --from=1h

# Resource-level breakdown
pup apm services resources \
  --service=api \
  --operation=GET \
  --env=production \
  --from=1h
```

### Step 2: Correlate with Logs

```bash
# High latency log entries
pup logs search \
  --query="@duration:>1000000000 service:api" \
  --from=1h \
  --limit=50

# Slow database queries
pup logs search \
  --query='@db.statement:* @duration:>500000000' \
  --from=1h
```

### Step 3: Check Resource Metrics

```bash
# Database query duration
pup metrics query \
  --query="avg:postgres.query.duration{service:api} by {host}" \
  --from=4h

# Cache hit ratio
pup metrics query \
  --query="avg:redis.keyspace.hits{service:api}" \
  --from=4h

# JVM heap usage (if applicable)
pup metrics query \
  --query="avg:jvm.heap_memory{service:api}" \
  --from=4h
```

## 3. Security Incident Investigation

### Step 1: Review Security Signals

```bash
# Critical signals
pup security signals list \
  --query="status:critical" \
  --from=24h \
  --limit=100

# Specific threat types
pup security signals list \
  --query="@workflow.rule.type:log_detection" \
  --from=24h

# Cloud security
pup security signals list \
  --query="source:cloudtrail" \
  --from=7d
```

### Step 2: Analyze Audit Logs

```bash
# Administrative actions
pup audit-logs search \
  --query="@action:access @target.type:role" \
  --from=24h \
  --limit=100

# Failed authentication
pup audit-logs search \
  --query="@action:authentication @status:error" \
  --from=24h

# API key activity
pup audit-logs search \
  --query="@target.type:api_key" \
  --from=7d
```

### Step 3: Check Infrastructure

```bash
# Unusual host activity
pup logs search \
  --query="source:agent @action:* sudo" \
  --from=24h

# Container events
pup containers list \
  --from=24h
```

## 4. Cost Analysis Workflow

### Step 1: Get Cost Overview

```bash
# Projected end-of-month costs
pup cost projected

# Cost by organization
pup cost by-org \
  --start-month=2024-01 \
  --end-month=2024-03

# Cost attribution by tags
pup cost attribution \
  --start=2024-01 \
  --end=2024-03 \
  --fields="team,env"
```

### Step 2: Analyze High-Cost Services

```bash
# Custom metrics volume
pup metrics query \
  --query="sum:datadog.estimated_usage.custom_metrics{*} by {service}" \
  --from=7d

# Log volume
pup logs aggregate \
  --query="*" \
  --from=1d \
  --compute="count" \
  --group-by="service"

# APM trace volume
pup metrics query \
  --query="sum:datadog.estimated_usage.apm.span_bytes{*} by {service}" \
  --from=7d
```

## 5. CI/CD Pipeline Failure Investigation

### Step 1: List Recent Pipeline Runs

```bash
# Recent pipelines
pup cicd pipelines list \
  --from=24h \
  --limit=50

# Failed pipelines only
pup cicd pipelines list \
  --query="@ci.status:error" \
  --from=24h

# Specific branch
pup cicd pipelines list \
  --branch="main" \
  --from=7d
```

### Step 2: Analyze Test Failures

```bash
# Failed tests
pup cicd tests search \
  --query="@test.status:fail" \
  --from=24h \
  --limit=100

# Flaky tests
pup cicd flaky-tests search \
  --query="service:my-service" \
  --include-history

# Test trends
pup cicd tests aggregate \
  --query="@test.status:*" \
  --from=7d \
  --compute="count" \
  --group-by="@test.status"
```

### Step 3: Correlate with Deployments

```bash
# Deployment events
pup cicd events search \
  --query="@ci.event_type:deployment" \
  --from=24h

# DORA metrics
pup cicd events aggregate \
  --query="*" \
  --from=30d \
  --compute="count" \
  --group-by="@ci.status"
```

## 6. Multi-Organization Investigation

### Step 1: List Available Sessions

```bash
# See all authenticated orgs
pup auth list
```

### Step 2: Compare Across Orgs

```bash
# Production org
pup monitors list --org=production --tags="env:prod"

# Staging org
pup monitors list --org=staging --tags="env:staging"

# Compare logs
pup logs search --query="status:error" --org=production --from=1h
pup logs search --query="status:error" --org=staging --from=1h
```

### Step 3: Aggregate Cross-Org Data

```bash
# Cost across orgs
pup cost by-org --start-month=2024-01 --end-month=2024-03

# Check auth status for each
pup auth status
```

## 7. Dashboard and SLO Health Check

### Step 1: List Dashboards

```bash
# All dashboards
pup dashboards list --limit=100

# Filter by title
pup dashboards list --title="API"

# Specific dashboard
pup dashboards get <dashboard-id>
```

### Step 2: Check SLOs

```bash
# List all SLOs
pup slos list --limit=100

# Filter by tags
pup slos list --tags="team:platform" --limit=50

# SLO details
pup slos get <slo-id>

# SLO history
pup slos history \
  --slo-id=<slo-id> \
  --from=7d \
  --to=now
```

### Step 3: Review Incidents

```bash
# Active incidents
pup incidents list --query="status:active"

# Recent incidents
pup incidents list --from=7d --limit=50

# Incident details
pup incidents get <incident-id>
```

## Output Tips

### JSON Processing

```bash
# Pretty print with jq
pup logs search --query="status:error" --from=1h | jq '.logs[] | {message, service, timestamp}'

# Extract specific fields
pup monitors list | jq '.monitors[] | {id, name, status}'

# Count results
pup logs search --query="status:error" --from=1h | jq '.logs | length'
```

### Table Output

```bash
# Human-readable tables
pup monitors list --output=table --limit=20
pup logs search --query="status:error" --output=table --from=1h
```

### YAML Output

```bash
# YAML for configuration files
pup monitors get <id> --output=yaml
pup dashboards get <id> --output=yaml
```

## Time Range Best Practices

| Investigation Type | Recommended Range | Notes |
|-------------------|-------------------|-------|
| Active incident | 15m - 1h | Start narrow, expand as needed |
| Daily check | 24h | Good balance of coverage and speed |
| Weekly review | 7d | Use aggregates to reduce data volume |
| Monthly analysis | 30d | Consider using aggregations |
| Historical trend | 30-90d | Use metrics rather than logs |

## Tips for Efficient Investigations

1. **Start with aggregates** - Get the big picture before drilling into details
2. **Use time boundaries** - Always specify `--from` and optionally `--to`
3. **Limit results** - Start with `--limit=20` or `--limit=50`
4. **Filter early** - Apply filters at the API level, not after fetching
5. **Group strategically** - Use `--group-by` to identify patterns
6. **Chain commands** - Use output from one command to inform the next
7. **Save common queries** - Use `pup alias` for frequently used queries
