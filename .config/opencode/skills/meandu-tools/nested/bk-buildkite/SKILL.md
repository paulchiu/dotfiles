---
name: bk-buildkite
description: "Query Buildkite builds, jobs, logs, pipelines, and agents via the bk CLI. Use when investigating CI failures, reading build logs, retrying builds, or any Buildkite interaction."
---

# Buildkite (bk CLI)

## Overview

The `bk` CLI provides access to Buildkite for managing builds, viewing job logs, investigating CI failures, and interacting with pipelines. Authenticated via OAuth with org `mryum` pre-configured.

## Prerequisites

Run `bk use mryum` at the start of a session if you get auth errors. The org is already configured but may need to be selected.

## Output Format

The CLI defaults to JSON output (`bk config set output_format json`). Use `--json` explicitly when needed. Use `--text` for human-readable output or when JSON is too verbose.

## Common Workflows

### 1. Investigate a CI Failure

```bash
# View a specific build, filtering to failed/broken jobs only
bk build view <build-number> -p mr-yum -s failed,broken

# Get the job log for a failed job (use the job UUID from build view output)
bk job log <job-uuid> -p mr-yum

# Strip timestamps for cleaner log output
bk job log <job-uuid> -p mr-yum --no-timestamps

# Tail the last N lines of a job log (pipe through tail)
bk job log <job-uuid> -p mr-yum --no-timestamps | tail -50
```

### 2. Check Build Status for a Branch

```bash
# View most recent build for current git branch
bk build view -p mr-yum

# View most recent build for a specific branch
bk build view -p mr-yum -b feature/my-branch

# List recent builds for a pipeline
bk build list -p mr-yum --limit 10

# List failed builds in the last hour
bk build list -p mr-yum --state failed --since 1h
```

### 3. Retry or Rebuild

```bash
# Retry a specific failed job
bk job retry <job-uuid>

# Rebuild an entire build
bk build rebuild <build-number> -p mr-yum

# Create a new build on a branch
bk build create -p mr-yum --branch main --commit HEAD --message "Manual rebuild"
```

### 4. View Pipeline Information

```bash
# List all pipelines
bk pipeline list

# View a specific pipeline
bk pipeline view mr-yum
```

### 5. Watch a Build in Real-Time

```bash
# Watch build progress (useful for monitoring after a push)
bk build watch <build-number> -p mr-yum
```

## Key Concepts

### Build States
- `running` - Build is currently executing
- `scheduled` - Build is queued but not started
- `passed` - All jobs passed
- `failed` - One or more jobs failed
- `canceled` - Build was canceled
- `blocked` - Build is waiting for manual unblock

### Job States
- `passed` - Job completed successfully
- `failed` - Job exited with non-zero status (actual failure)
- `broken` - Job was not run because a dependency failed (cascading)
- `running` - Job is currently executing
- `scheduled` - Job is queued
- `skipped` - Job was skipped by pipeline logic
- `canceled` - Job was canceled
- `not_run` - Job has not been run

When investigating failures, filter with `-s failed` to see only jobs that actually failed (not `broken` which are just cascading). Use `-s failed,broken` to see both.

### Pipeline Slugs

For the mr-yum monorepo, the pipeline slug is `mr-yum`. Always pass `-p mr-yum` when working with monorepo builds. For other repos, use the repo name as the pipeline slug.

### Job UUIDs

Job UUIDs are found in the `id` field of job objects in build view output. They look like `019d8627-e570-426b-b157-e67c1c56ef9f`. Use these with `bk job log` and `bk job retry`.

## Build View Output (JSON)

When using `bk build view`, the JSON output contains:
- `number` - Build number
- `state` - Build state (passed, failed, etc.)
- `commit` - Git commit SHA
- `branch` - Git branch name
- `message` - Commit message
- `jobs` - Array of job objects with:
  - `id` - Job UUID (use with `bk job log`)
  - `name` - Job label (e.g. ":eslint: linting - back-end")
  - `state` - Job state
  - `exit_status` - Exit code (null if not finished)
  - `command` - The shell command that was run
  - `raw_log_url` - API URL for raw logs (use `bk job log` instead)

## Filtering Builds

```bash
# By duration (find slow builds)
bk build list -p mr-yum --duration ">20m" --limit 10

# By commit SHA
bk build list -p mr-yum --commit abc123

# By creator
bk build list -p mr-yum --creator "paul@meandu.com"

# By metadata
bk build list -p mr-yum --meta-data env=production

# Combine filters
bk build list -p mr-yum --state failed --branch main --since 24h
```

## API Access (Advanced)

For endpoints not covered by built-in commands:

```bash
# Direct API call
bk api /organizations/mryum/pipelines/mr-yum/builds/74054

# With query parameters
bk api "/organizations/mryum/pipelines?page=1&per_page=30"
```

## Global Flags

- `-p, --pipeline` - Pipeline slug (e.g. `mr-yum`)
- `-b, --branch` - Filter by branch
- `-s, --job-states` - Filter jobs by state (comma-separated)
- `-y, --yes` - Skip confirmation prompts
- `--no-input` - Disable interactive prompts (important for agent use)
- `--no-pager` - Disable pager output
- `--json` / `--text` / `--yaml` - Output format
- `-o, --output` - Alternative output format flag

## Anti-Patterns to Avoid

- Don't use `bk build view` without `-p mr-yum` when outside a git repo with a configured pipeline
- Don't look at `broken` jobs to find root cause failures (those are cascading). Filter with `-s failed` first
- Don't parse raw_log_url manually; use `bk job log` instead
- Don't forget `bk use mryum` if you get auth errors
- Don't use `--json` and `-o json` together (they conflict)
