---
model: haiku
name: fix-redis
description: "Fix Redis 'port is already allocated' / port 6379 conflicts for Docker or OrbStack. Use when container startup fails on 6379, when 'docker compose up' reports 'Bind for 0.0.0.0:6379 failed: port is already allocated', or when asked to fix Redis or free port 6379."
---

# Fix Redis Port Conflict

## Overview

When a Docker/OrbStack container like `dev-env-redis-1` fails to start with:

```
Bind for 0.0.0.0:6379 failed: port is already allocated
```

another Redis container (or a host process) is already bound to port 6379. Follow the steps below in order. Do not skip steps and do not reorder them.

## Workflow

### Step 1: Identify what is bound to port 6379

Run exactly:

```bash
lsof -i :6379 -P -n
```

Interpret the result:

- **No output (exit code 1):** nothing is bound to 6379. The port is already free. Skip to Step 5.
- **Output where the COMMAND column shows `OrbStack`, `com.docker`, or `docker`:** the port is held by a Docker container, not a host process. Go to Step 2.
- **Output where the COMMAND column shows anything else** (e.g. `redis-ser` for a raw `redis-server`): the port is held by a host process. Note the PID column value, then go to Step 3.
- **Command fails with any other error** (e.g. `lsof: command not found`): stop and report the exact error to the user. Do not continue.

### Step 2: Find the Docker container publishing port 6379

Run exactly:

```bash
docker ps --filter "publish=6379" --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
```

Interpret the result:

- **One container listed** (e.g. `manage-api-redis-1`): note its name from the NAMES column, then go to Step 3.
- **More than one container listed:** note all names, then go to Step 3 and stop each one (after confirming, per Step 3).
- **Only the header row, no containers:** Docker holds the port but no running container publishes it. Run `docker ps -a --filter "publish=6379"` to check for a stuck container. If still nothing, stop and report to the user that the port is held by Docker/OrbStack itself and a Docker Desktop/OrbStack restart may be needed. Do not guess further.
- **Command fails** (e.g. daemon not running): stop and report the exact error to the user.

### Step 3: Confirm with the user, then stop the owner

Before stopping anything, tell the user exactly which container name(s) or process (command + PID) is holding port 6379, and that you are about to stop it. The user may want that service left running and prefer to remap the new container to a different port instead. If the user has already explicitly asked you to free the port or stop the conflict, proceed without asking again; otherwise wait for their go-ahead.

**If the owner is a Docker container**, run:

```bash
docker stop <container-name>
```

Expected output: the container name echoed back. If the command errors, stop and report the exact error.

**If the owner is a host process** (only when Step 1 showed a non-Docker command), run:

```bash
kill <PID>
```

using the PID noted in Step 1. If `kill` reports "Operation not permitted", report that to the user and ask before trying `sudo kill <PID>`. Do not use `kill -9` unless a plain `kill` did not free the port after Step 4.

Guardrails:

- Always prefer `docker stop` over `kill` when the owner is a container.
- Never run `docker rm` unless the user explicitly asks. Stopping is reversible; removing discards the container's state.

### Step 4: Confirm the port is free

Run exactly:

```bash
lsof -i :6379 -P -n || echo "port is free"
```

- **Output is `port is free`:** go to Step 5.
- **Output still lists a process:** the port is not free yet. Wait 2 seconds and run the command once more. If it still lists a process, go back to Step 1 (there may be a second owner). If you have already looped once, stop and report what is still holding the port.

### Step 5: Retry the original command

Re-run whatever command originally failed (e.g. `docker compose up`). If it succeeds, report success and which owner was stopped. If it fails again with the same port error, stop and report the full error output to the user. Do not repeat the whole workflow more than once without asking.

## Notes

- If multiple Redis containers from different projects routinely conflict, suggest mapping one to a non-default host port (e.g. `6380:6379`) in its compose file. Suggest only; do not edit compose files unless asked.
- The same pattern applies to any port conflict: swap `6379` for the offending port number in every command above.
