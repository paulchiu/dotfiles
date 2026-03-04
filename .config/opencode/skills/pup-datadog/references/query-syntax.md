# Datadog Query Syntax Reference

Complete query syntax reference for all Datadog data types when using the pup CLI.

## Logs

### Basic Syntax

```
status:error                # Status filter
service:web-app             # Service name
@attr:value                 # Log attribute (with @ prefix)
host:i-*                    # Wildcards with *
"exact phrase"              # Exact phrase matching
```

### Operators

```
status:error AND service:api      # AND operator
status:error OR status:warn       # OR operator
NOT status:info                   # NOT operator
-status:info                      # Negation shorthand
```

### Examples

```bash
# Errors from a specific service
pup logs search --query="status:error service:payment-service" --from=1h

# Failed login attempts with wildcards
pup logs search --query="@event.action:failed @user.name:john*" --from=24h

# Multiple services excluding debug
pup logs search --query="(service:api OR service:web) -status:debug" --from=1h
```

## Metrics

### Syntax Format

```
<aggregation>:<metric_name>{<filter>} by {<group>}
```

### Aggregations

- `avg` - Average
- `sum` - Sum
- `min` - Minimum
- `max` - Maximum
- `count` - Count

### Examples

```bash
# CPU usage by host
pup metrics query --query="avg:system.cpu.user{env:prod} by {host}" --from=1h

# Request count by service
pup metrics query --query="sum:trace.http.request.hits{*} by {service}" --from=1h

# Memory usage filtered by service
pup metrics query --query="avg:system.mem.used{service:web-app}" --from=4h
```

## APM (Application Performance Monitoring)

### Key Fields

```
service:<name>              # Service name
resource_name:<path>        # Resource/endpoint path
@duration:>5000000000       # Duration in NANOSECONDS (5 seconds)
@duration:>5s               # Duration shorthand (also nanoseconds)
status:error                # Error status
operation_name:<op>         # Operation name
env:production              # Environment tag
```

### Important: APM Durations Are in NANOSECONDS

```
1 second      = 1000000000 ns
1 millisecond = 1000000 ns
5 seconds     = 5000000000 ns
100ms         = 100000000 ns
```

### Examples

```bash
# Slow traces (>5 seconds)
pup apm traces search --query="@duration:>5000000000" --from=1h

# Errors from a specific service
pup apm traces search --query="service:payment-api status:error" --from=1h

# Specific resource with high latency
pup apm traces search --query="resource_name:/api/v1/checkout @duration:>1000000000" --from=1h
```

## Monitors

### List/Search Filters

```bash
# Filter by tags
pup monitors list --tags="env:production,team:platform"

# Search by name substring
pup monitors list --name="payment"

# Full-text search
pup monitors search --query="status:Alert"
pup monitors search --query="type:metric"
```

### Monitor Status Values

- `OK` - Monitor is passing
- `Alert` - Monitor is triggered
- `Warn` - Warning state
- `No Data` - No data received
- `Skipped` - Evaluation skipped

## Events

### Syntax

```
sources:nagios,pagerduty      # Source filter
status:error                  # Status
tags:env:prod                 # Tag filter
priority:normal               # Priority level
host:web-01                   # Host filter
```

### Examples

```bash
# Deployment events
pup events search --query="source:jenkins tags:deploy" --from=24h

# High priority alerts
pup events search --query="priority:normal status:error" --from=1h
```

## RUM (Real User Monitoring)

### Syntax

```
@type:error                   # Error type
@session.type:user            # Session type
@view.url_path:/checkout      # URL path
@action.type:click            # Action type
service:<app-name>            # Application name
```

### Examples

```bash
# JavaScript errors on checkout
pup rum search --query="@type:error @view.url_path:/checkout" --from=1h

# User clicks on specific element
pup rum search --query="@action.type:click @action.target.name:submit-btn" --from=4h
```

## Security Signals

### Syntax

```
@workflow.rule.type:log_detection    # Rule type
source:cloudtrail                     # Signal source
@network.client.ip:10.0.0.0/8       # IP range
status:critical                      # Signal status
@evt.name:ConsoleLogin               # Event name
```

### Examples

```bash
# Critical security signals
pup security signals list --query="status:critical" --from=1d

# CloudTrail login events
pup security signals list --query="source:cloudtrail @evt.name:ConsoleLogin" --from=24h

# Specific rule type
pup security signals list --query="@workflow.rule.type:cloud_configuration" --from=7d
```

## CI/CD Events

### Syntax

```
@ci.pipeline.name:deploy      # Pipeline name
@ci.provider.name:github      # CI provider
@git.branch:main              # Git branch
@ci.status:error              # Status
service:my-service            # Service name
```

### Examples

```bash
# Failed pipelines
pup cicd pipelines list --query="@ci.status:error" --from=24h

# Specific branch deployments
pup cicd pipelines list --branch="main" --from=7d

# Test events
pup cicd tests search --query="@test.status:fail" --from=24h
```

## Traces

### Syntax

```
service:<name>                # Service name
resource_name:<path>          # Resource path
@duration:>5s                 # Duration (nanoseconds shorthand)
env:production                # Environment
status:error                  # Error status
@http.status_code:500         # HTTP status code
```

### Examples

```bash
# 500 errors from API
pup apm traces search --query="service:api @http.status_code:500" --from=1h

# Traces from production environment
pup apm traces search --query="env:production" --from=4h --limit=100

# Database operations taking >1 second
pup apm traces search --query="operation_name:postgres.query @duration:>1000000000" --from=1h
```

## Audit Logs

### Syntax

```
@actor.type:user              # Actor type
@actor.email:user@example.com # Actor email
@action:authentication        # Action type
@target.type:api_key          # Target resource type
@status:success               # Action status
```

### Examples

```bash
# API key operations
pup audit-logs search --query="@target.type:api_key" --from=7d

# Failed authentication attempts
pup audit-logs search --query="@action:authentication @status:error" --from=24h

# Specific user activity
pup audit-logs search --query="@actor.email:admin@example.com" --from=30d
```

## Common Patterns

### Combining Conditions

```
# AND (implicit or explicit)
service:api AND status:error
service:api status:error

# OR
service:api OR service:web

# NOT
-status:debug
NOT status:debug

# Grouping
(service:api OR service:web) AND status:error
```

### Wildcards

```
host:web-*                    # Starts with "web-"
host:*-prod                   # Ends with "-prod"
host:*api*                    # Contains "api"
```

### Range Queries

```
@duration:[1000000 TO 5000000]     # Duration between 1-5ms
@http.status_code:[400 TO 599]    # HTTP 4xx and 5xx errors
@timestamp:[2024-01-01 TO 2024-01-31]
```

## Tips and Tricks

1. **Use quotes for exact matching** - `"error message"` vs `error message`
2. **Escape special characters** - `host:web\-server` for literal hyphen
3. **Check field names** - Use `@` prefix for log attributes, plain names for tags
4. **Start simple** - Begin with one condition, add more as needed
5. **Use aggregates first** - Count/group before fetching individual items
6. **Time ranges matter** - Narrow time ranges are faster and cheaper
