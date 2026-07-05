# Diagnosing Buildkite failures: flake vs real

Before retrying or fixing anything for a `buildkite/...` check, classify the failure. Pull the failed-job log via the `bk-buildkite` skill (`bk job log <uuid> -p <pipeline> --no-timestamps`) and grep for the patterns below.

## Infra signals (retry the job, do not change code)

| Pattern in log | Meaning |
|---|---|
| `dependency <service> failed to start ... exited (133)` | Docker-compose dep container died on startup (common: redpanda, setup-crdb) |
| `service "<name>" didn't complete successfully` | Compose dependency failed health/init |
| `exit_status: -1` with the test log truncated mid-run | Agent killed the process (OOM, timeout, agent lost) |
| `exit_status: 137` | SIGKILL, usually OOM |
| `agent lost` in the build event timeline | Buildkite agent disconnected |
| Connection timeouts to ECR/docker registry, `i/o timeout`, `connection reset` against AWS endpoints | Transient network |

## Real failure signals (do NOT retry, surface to the user or fix)

| Pattern | Meaning |
|---|---|
| `FAIL <test/path>` followed by `● Test ›` and a diff | Real test assertion failure |
| `Tests: <N> failed` in the summary block | Real test failure(s) |
| TypeScript compile errors with explicit `error TS` lines | Real build break |
| ESLint errors that don't match the lint-fix patterns in the SKILL.md fix loop | Real lint regression |

## Pre-existing soft failures (note but do not act)

Before treating a non-required failure as new, compare against `main`. If the same job is also failing on `main`'s most recent passed/failing build (e.g. `:judge: licensing`, `:mag: checking unused` on the `manage` repo), it is pre-existing project debt; the rollup `buildkite/<pipeline>` may still pass or the check may be advisory. Do not retry, do not fix, just note in the loop summary.

```bash
# Fast comparison: list failed jobs on the latest main build vs the PR build
bk build view <pr-build> -p <pipeline> | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(j['name'] for j in d['jobs'] if j.get('state')=='failed' and j.get('type') in ('script','command')))"
bk build list -p <pipeline> --branch main --limit 5 --json | python3 -c "import json,sys; [print(b['number'], b['state']) for b in json.load(sys.stdin)]"
# Then `bk build view <main-build>` for the most recent and compare failed-job names.
```

## Retrying a single Buildkite job

The official `bk job retry <uuid>` requires `graphql` token scope. If your token lacks it (typical for read-heavy tokens), use the REST API directly via `bk api`:

```bash
bk api /pipelines/<pipeline>/builds/<build-number>/jobs/<job-uuid>/retry --method PUT
```

Required token scope: `write_builds` (REST). On success Buildkite reschedules just that one job. The build's overall state will return to `pending` until the retry completes.

**Per-job retry quota: jobs can only be retried once.** If the REST call returns `400 {"message":"Jobs can only be retried once"}`, that job has already used its retry slot (either by a prior tend-pr iteration, the user, or an auto-retry rule). At that point, ask the user to retry it manually from the Buildkite UI; they can override the quota in the web UI in seconds. Do NOT fall back to `bk build rebuild <number>`: a full-build rebuild reruns every job (10+ shards, 10-20 minutes) when only one job needs another go, and bills the agent fleet unnecessarily. Prompting the user is faster than rebuilding.

When you do retry: log the retry in the loop's reason (e.g. `infra-flake retry: redpanda exit 133, job <uuid>`), and on the next iteration check whether the retry succeeded before considering further action.
