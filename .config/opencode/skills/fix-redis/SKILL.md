---
name: fix-redis
description: Fix "port is already allocated" errors for Redis (port 6379) when starting Docker/OrbStack containers. Use when the user reports a Redis port conflict, a failed Docker container startup citing port 6379, or asks to "fix redis", "free port 6379", or "shut down whatever is using redis".
---

# Fix Redis Port Conflict

## Overview

When a Docker/OrbStack container like `dev-env-redis-1` fails to start with:

```
Bind for 0.0.0.0:6379 failed: port is already allocated
```

another Redis container (or host process) is already bound to port 6379. This skill identifies the conflicting process/container and stops it so the new container can start.

## Workflow

### 1. Identify what is bound to port 6379

```bash
lsof -i :6379 -P -n
```

If the listener is `OrbStack` or `com.docker`, the port is held by a Docker container (not a host process). Proceed to step 2. If it's a raw `redis-server` or other process, skip to step 3.

### 2. Find the Docker container publishing port 6379

```bash
docker ps --filter "publish=6379" --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
```

This reveals the container holding the port (e.g. `manage-api-redis-1`).

### 3. Stop the offending owner

**Docker container:**

```bash
docker stop <container-name>
```

**Host process** (only if step 1 showed a non-Docker process):

```bash
kill <PID>
```

Prefer `docker stop` over `kill` whenever the owner is a container. Do not `docker rm` unless explicitly asked: stopping is reversible, removing discards the container's state.

### 4. Confirm the port is free and retry

```bash
lsof -i :6379 -P -n || echo "port is free"
```

Then re-run whatever command failed (e.g. `docker compose up`).

## Notes

- Always show the user which container/process is holding the port before stopping it. They may want that service left running and prefer to reconfigure the new container to a different port instead.
- If multiple Redis containers from different projects are routinely conflicting, suggest mapping one to a non-default host port (e.g. `6380:6379`) in its compose file.
- The same pattern applies to any port conflict: swap `6379` for the offending port number.
