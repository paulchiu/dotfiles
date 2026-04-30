---
name: tend-pr
description: "Maintain one open PR until merge or timeout: rebase onto main, diagnose CI/build failures, push fixes. Use for tend, caretake, babysit, shepherd, monitor, watch, keep alive, or keep green/mergeable."
---

# Tend a Pull Request

## Overview

Drives a self-paced `/loop` that repeatedly checks one specific pull request, reacts to CI failures by attempting fixes, rebases and pushes when the branch falls behind main, and stops when the PR merges or a timeout elapses. The goal is "hands-off until it lands" — the user walks away and comes back to either a merged PR or an explicit decision point.

## Inputs to collect before starting

Ask the user for any of the following that aren't already obvious from the request:

1. **PR identifier** — a PR number, URL, or branch name. If the user said "this PR" without context, try `gh pr view` in the current repo first; otherwise ask.
2. **Loop interval** — how often to check. Default `10 min`. Accept `5 min`, `10 min`, `20 min`, `1 h`, etc. Snap to 270s if the user picks 5 min (prompt-cache TTL consideration — see `/loop` skill notes if unsure).
3. **Timeout** — how long to keep tending before handing back to the user. Default `2 h`. Accept `1 h`, `2 h`, `3 h`, etc. At timeout, do not silently stop — ask the user whether to extend, stop, or hand off.
4. **Collision handling** — if any existing `/loop` or scheduled wake-up already targets the same PR, ask whether to (a) cancel the existing one and start fresh, (b) skip starting a new one and let the existing one continue, or (c) run both (rarely correct — warn).

Confirm all four values back to the user in one sentence before kicking off the loop.

## Workflow

### 1. Check for existing loops on this PR

Before arming anything, list active scheduled tasks and look for any whose prompt references the same PR number or branch:

```bash
# CronList equivalent — use whatever the runtime exposes. In Claude Code:
# call CronList and TaskList, scan for matching pr:<N> or branch name in prompts/reasons.
```

If a match is found, present it to the user with the existing cadence and offer the three collision-handling choices above. Do not proceed until the user picks.

### 2. Resolve PR state

```bash
gh pr view <pr> --json number,state,mergeable,mergeStateStatus,headRefName,headRefOid,isDraft,mergedAt,baseRefName
```

Capture the PR number, head branch name, base branch (usually `main`), and current head SHA. Record the start epoch and compute the stop epoch (start + timeout in seconds).

### 3. Run the tending iteration now

Each iteration does the following, in order, stopping as soon as a terminal condition is met:

**a. Check merge status.** If `state == MERGED`, stop the loop and report success with merge URL and timestamp.

**b. Check timeout.** If `now >= stop_epoch`, stop the loop and ask the user whether to extend (and by how long), stop, or hand off. Do not schedule another wake-up until they answer.

**c. Check CI status.**

```bash
gh pr checks <pr>
```

- All `pass`/`success`: nothing to fix. Move on.
- Any `pending`/`in_progress`/`queued`: nothing to do; the next iteration will recheck.
- Any `fail`/`failure`/`cancelled`: fetch the failing job's log, diagnose, attempt a fix. See "Fix loop" below.

**For any Buildkite check** (i.e. a check named `buildkite/...`), use the `bk-buildkite` skill rather than raw `gh` output. That skill handles build/job/log queries, agent status, and retriggers via the `bk` CLI and knows the repo's pipeline slugs. Invoke it whenever a Buildkite check is pending (to get a better ETA) or failing (to read the failing job log and decide between retry vs code fix).

**d. Check rebase need.** Fetch `origin/<base>` and compare:

```bash
cd <worktree> && git fetch origin <base> --quiet && git rev-list --left-right --count origin/<base>...HEAD
```

The left count is commits-behind. If behind > 0 AND `mergeStateStatus` is `BEHIND` or a rebase would unblock merge, run the **preflight branch guard** below before touching history:

```bash
current=$(git rev-parse --abbrev-ref HEAD)
[ "$current" = "<pr-head-branch>" ] || { echo "preflight: on $current, expected <pr-head-branch>"; exit 1; }
[ "$current" != "<base>" ] && [ "$current" != "main" ] || { echo "preflight: refusing to rebase/push on base branch"; exit 1; }
```

If either assertion fails, stop the loop and ask the user: something has switched the worktree off the PR head, and blindly rebasing would be destructive. Only once the preflight passes:

```bash
git rebase origin/<base>
```

Resolve conflicts if safely resolvable (obvious one-side-only changes, auto-merge-able imports). If conflicts require human judgment, stop the loop and ask the user. After a clean rebase, push with `--force-with-lease`:

```bash
git push --force-with-lease
```

**Never** use bare `--force`. **Never** rebase `main` itself. The preflight guard above must run before every rebase or force-push attempt, not just the first.

**e. Check branch drift.** If the remote head SHA differs from what you last pushed (someone else pushed), re-read PR state before acting; don't blindly force-push over a teammate's work.

**f. Check for new review comments.** Look for new comments or reviews from CodeRabbit, other bots, or human reviewers since the last iteration:

```bash
gh pr view <pr> --json comments,reviews
```

(The `reviewThreads` field is not exposed by `gh pr view --json`. If you need per-file inline review threads, fetch them separately via `gh api graphql` or a compatible extension.)

Track the latest comment/review timestamp across iterations (carry it forward in the wake-up prompt alongside start/stop epoch and PR number). If new comments have arrived:

- **Do NOT stop the loop.** Continue tending (CI, rebase) as normal.
- **Do NOT attempt to address the comments in the loop.** These need human judgment.
- Surface them prominently in the next loop summary/reason: list who commented (e.g. "CodeRabbit", reviewer handles), a count of new comments, and a one-line gist if easily extractable. Use a `PushNotification` (or runtime equivalent) to ping the user so they know to review and decide what to do.

### Fix loop (for CI failures)

Reserve aggressive fixing for unambiguous, reversible failures:

- **Lint/format failures**: run the repo's fix command (`npm run fix:formatting`, `npm run fix:linting`, `pnpm lint --fix`, `cargo fmt`, etc.), commit with a message like `chore: fix linting`, push.
- **Flaky test or infra failure**: classify with the patterns in "Diagnosing Buildkite failures" below. If clearly infra (not the code), retry the specific failed job via the REST API workflow described there. If the per-job retry quota is exhausted, ask the user to retry from the Buildkite UI; do NOT rebuild the entire build (too slow and wasteful). For non-Buildkite providers, fall back to `gh run rerun <run-id> --failed` or the platform equivalent.
- **Snapshot mismatch introduced by this branch**: do NOT auto-regenerate snapshots. Hand back to the user, snapshot diffs need human eyes.
- **Type errors or logic failures**: do NOT guess fixes in a loop. Stop and ask the user; this skill is for keeping a PR fresh, not for writing code under autopilot.

Safety rules for every fix attempt:

- Run the repo's full local validation (typecheck + test + lint) before pushing a fix.
- Never skip hooks (`--no-verify`) unless the user has explicitly authorised it for this PR.
- Never push to `main` directly.
- If two fix attempts fail consecutively (regardless of fix type), stop and hand back.

### Diagnosing Buildkite failures: flake vs real

Before retrying or fixing anything for a `buildkite/...` check, classify the failure. Pull the failed-job log via `bk-buildkite` (`bk job log <uuid> -p <pipeline> --no-timestamps`) and grep for the patterns below.

**Infra signals (retry the job, do not change code):**

| Pattern in log | Meaning |
|---|---|
| `dependency <service> failed to start ... exited (133)` | Docker-compose dep container died on startup (common: redpanda, setup-crdb) |
| `service "<name>" didn't complete successfully` | Compose dependency failed health/init |
| `exit_status: -1` with the test log truncated mid-run | Agent killed the process (OOM, timeout, agent lost) |
| `exit_status: 137` | SIGKILL, usually OOM |
| `agent lost` in the build event timeline | Buildkite agent disconnected |
| Connection timeouts to ECR/docker registry, `i/o timeout`, `connection reset` against AWS endpoints | Transient network |

**Real failure signals (do NOT retry, surface to the user or fix):**

| Pattern | Meaning |
|---|---|
| `FAIL <test/path>` followed by `● Test ›` and a diff | Real test assertion failure |
| `Tests: <N> failed` in the summary block | Real test failure(s) |
| TypeScript compile errors with explicit `error TS` lines | Real build break |
| ESLint errors that don't match the lint-fix patterns above | Real lint regression |

**Pre-existing soft failures (note but do not act):**

Before treating a non-required failure as new, compare against `main`. If the same job is also failing on `main`'s most recent passed/failing build (e.g. `:judge: licensing`, `:mag: checking unused` on the `manage` repo), it is pre-existing project debt; the rollup `buildkite/<pipeline>` may still pass or the check may be advisory. Do not retry, do not fix, just note in the loop summary.

```bash
# Fast comparison: list failed jobs on the latest main build vs the PR build
bk build view <pr-build> -p <pipeline> | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(j['name'] for j in d['jobs'] if j.get('state')=='failed' and j.get('type') in ('script','command')))"
bk build list -p <pipeline> --branch main --limit 5 --json | python3 -c "import json,sys; [print(b['number'], b['state']) for b in json.load(sys.stdin)]"
# Then `bk build view <main-build>` for the most recent and compare failed-job names.
```

**Retrying a single Buildkite job**

The official `bk job retry <uuid>` requires `graphql` token scope. If your token lacks it (typical for read-heavy tokens), use the REST API directly via `bk api`:

```bash
bk api /pipelines/<pipeline>/builds/<build-number>/jobs/<job-uuid>/retry --method PUT
```

Required token scope: `write_builds` (REST). On success Buildkite reschedules just that one job. The build's overall state will return to `pending` until the retry completes.

**Per-job retry quota: jobs can only be retried once.** If the REST call returns `400 {"message":"Jobs can only be retried once"}`, that job has already used its retry slot (either by a prior tend-pr iteration, the user, or an auto-retry rule). At that point, ask the user to retry it manually from the Buildkite UI; they can override the quota in the web UI in seconds. Do NOT fall back to `bk build rebuild <number>`: a full-build rebuild reruns every job (10+ shards, 10-20 minutes) when only one job needs another go, and bills the agent fleet unnecessarily. Prompting the user is faster than rebuilding.

When you do retry: log the retry in the loop's reason (e.g. `infra-flake retry: redpanda exit 133, job <uuid>`), and on the next iteration check whether the retry succeeded before considering further action.

### 4. Schedule the next wake-up

Use the runtime's dynamic-mode scheduler (Claude Code: `ScheduleWakeup`; other runtimes: their equivalent). `delaySeconds` should be the user-chosen interval in seconds, clamped per cache-TTL rules from the host `/loop` skill (prefer 270s if the user said "5 min"). The next-iteration prompt must carry forward:

- start epoch
- stop epoch
- PR number
- worktree path

so later iterations have everything they need without re-asking the user.

### 5. At timeout, ask to continue

When `now >= stop_epoch`, do NOT reschedule. Post a short summary: total iterations, fixes applied, current PR state, current CI state, current rebase state. Then ask: "Extend by how long? Stop? Or hand off to a human/owner?" Treat the three options as mutually exclusive and wait for the user before doing anything else.

## Notes

- This skill is for **one PR at a time**. If the user wants to tend several, start separate loops, and name them distinctly so the collision check in Step 1 works.
- Terminal conditions other than merge: the PR closed without merging, the branch was deleted, the base branch changed out from under us. Any of these stops the loop and reports back.
- If the repo's pre-commit hooks require `node_modules` or similar locally-materialised deps and the worktree doesn't have them, symlink from the main checkout at loop setup time rather than disabling hooks.
- If global gitignore hides `.claude/`, `.config/`, or similar tracked directories during commit, override with `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.excludesFile GIT_CONFIG_VALUE_0=/dev/null` for the single commit. Do not skip hooks to work around it.
