---
name: linear-do
description: "Implement a Linear issue end-to-end: read the ticket, code, commit, open a PR, monitor CI. Use for do/implement/work on a Linear issue, or when given a Linear URL/ID with intent to implement. Includes an autonomous 'ship' mode that runs to merge without checkpoints (triggered by 'ship', 'ship the ticket', 'autonomously', '--auto')."
---

# Linear Do

Implement a Linear issue end-to-end: read the ticket, make the changes, commit, open a PR, and monitor CI until green.

Input: a Linear issue URL or identifier (e.g. `https://linear.app/mr-yum/issue/CUSM-642/...` or `CUSM-642`).

## Operating modes

- **Interactive** (default): pause at Phase 2 for clarifying questions, ask before marking ready/merging.
- **Autonomous** (opt-in): ticket-to-merge without checkpoints. Triggered by "ship", "ship the ticket", "ship-it", "autonomously", "end-to-end", or `--auto`. Follow the same workflow with the deltas in "Autonomous mode" below, and keep a decision log throughout.

## Workflow

### Phase 1: Understand

1. Fetch the issue via `mcp__claude_ai_Linear__get_issue` (preferred) or `linear issue view <ID>`. Read the description, acceptance criteria, implementation guidance, and comments. In an unfamiliar repo, hand the breadth pass (entry points, conventions, test layout) to an Explore subagent in parallel with the ticket read, and carry forward only its conclusions.
2. **Capture the git branch name returned by the Linear API** (e.g. `feature/cusm-642-remove-db-schema-compat-matrix`). That is the branch name for Phase 3. If the API returned none, fall back to `feature/<issue-id-lowercase>-short-description` or `fix/...`.

### Phase 2: Ask questions

Before writing code, ask the user about anything unclear: which repo/directory, missing acceptance criteria or verification steps, scope boundaries, environment setup. Also ask: **worktree or branch in the current directory?** (Default: current directory.) Do not start implementing until the user confirms you have enough context. If implementation later reveals the issue needs a spike or is bigger than expected, stop and discuss.

### Phase 3: Set up

Confirm the working tree is clean; if not, ask how to handle uncommitted changes.

- **Worktree:** `git worktree add ../<repo-name>-<issue-id> -b <branch-name> main`, then work inside it for all remaining phases. After merge (or abandonment): `git worktree remove ../<repo-name>-<issue-id>`.
- **Branch (default):** `git checkout main && git pull`, then `git checkout -b <branch-name>`.

### Phase 4: Implement

Make the changes, following existing repo conventions. Keep scope to exactly what the ticket describes; no opportunistic refactors. Run the verification commands listed in the issue (typecheck, lint, tests) and fix failures before proceeding.

### Phase 5: Commit

Use the **git-commit** skill. Stage the relevant files; the branch name carries the issue code, so the skill handles prefixing.

### Phase 6: Create PR

Use the **gh-pr** skill (pushes the branch, creates a draft PR). Note the PR number.

### Phase 7: Monitor CI

1. `gh pr checks <number>`. If pending, use `/loop` to poll every 3 minutes.
2. On failure, use the **bk-buildkite** skill: `bk use mryum`, then `bk build view <build-number> -p <pipeline> -s failed,broken` to find the failed job, then `bk job log <job-uuid> -p <pipeline> --no-timestamps` for logs. Fix, commit (git-commit skill), push, keep monitoring.
3. Once green, ask the user whether to mark ready (`gh pr ready <number>`), request reviewers, enable auto-merge, or update the Linear issue status.

## Autonomous mode

Deltas to the workflow above. These defaults replace the interactive choices.

**Phase 1:** also capture acceptance criteria as an explicit list (each AC becomes a test target in 4b) and the ticket's verification commands (they define "green").

**Phase 2: skip.** Defaults: repo = the one Linear's git URL points at (or the repo Paul ran the skill from); worktree = mandatory; scope = exactly the ticket. On a true blocker (missing repo, contradictory AC), escalate rather than invent answers.

**Phase 3:** always a worktree: `git worktree add ../<repo>-<issue-id-lowercase> -b <branch-name> main`.

**Phase 4: plan first.** Create a TaskCreate list: one task per AC plus one per file you expect to change. Track in_progress/completed; if the plan turns out wrong, update the tasks rather than silently diverging.

**Phase 4b (new): AC test loop.** Before commit:

1. Use the test framework already in the repo; never introduce a new one.
2. Write or update at least one test per AC. If an AC is fundamentally untestable ("looks better"), log that decision and skip it.
3. Run tests plus the ticket's verification commands until all pass. **Iteration cap: 5 failed runs**, then escalate with failing test names, fix attempts, and your blocker hypothesis.

**Phase 5b (new): self-audit before PR.** Spawn a `general-purpose` subagent and frame it to refute, not confirm: give it only the diff and the AC list (not your working context) and ask it to disprove the claim "this diff satisfies every AC and is PR-ready". A fresh reader's objections are the signal; your own review is biased by having written the code. It also checks gh-pr's requirements:

- Branch name carries the issue code in parseable form (`feature/<id>-...` or `fix/<id>-...`).
- If `.github/pull_request_template.md` exists, note sections the PR description must fill.
- Every commit on the branch is conventional-commit format.
- No leftover placeholders (TODO, FIXME, `xxx`, lorem ipsum) in the diff.
- Australian spelling in comments and user-facing strings.

Fix any blockers (spelling/comment-only nits may be accepted and logged), then create the PR.

**Phase 7:** once green, do not ask; run `gh pr ready <number>` and continue. CI fix-loop cap: 5 failed runs, then escalate.

**Phase 8 (new): review feedback loop.** Poll every 5 minutes via `/loop`, max 30 minutes. Each iteration read `gh pr view <number> --comments` (CodeRabbit posts here) and `gh pr view <number> --json reviews`. For each new comment:

- Actionable and clearly correct: implement, commit, push.
- Stylistic nit you disagree with: post a brief polite reply with your reasoning. Never silently ignore.
- Substantive disagreement (reviewer wants a different approach): escalate; do not unilaterally rewrite.

Draft **any human-facing reply** via the `writing-tone` skill before posting. Default to a blockquote-led inline reply (writing-tone example 7): quote the relevant line, then respond. No freeform paragraphs that paraphrase the comment.

Exit when an approving review lands AND CI is green, or 30 minutes elapse.

**Phase 9 (new): merge and archive.** Once approved and green:

1. `gh pr checks <number>` to verify, then `gh pr merge <number> --auto --squash`.
2. After merge confirms, `git worktree remove ../<repo>-<issue-id-lowercase>`.
3. Move the Linear ticket to the team's Done state. For Clean Kitchen task force, use the state IDs in MEMORY.md (`Linear CKTF Team State IDs`); for other teams, look up via `mcp__claude_ai_Linear__get_team`.

## Fable notes

Written for Fable 5; lean on its strengths rather than walking the phases mechanically:

- Delegate context-heavy reading (repo exploration, long CI logs) to subagents and keep the main thread for decisions and code; a bk job log pasted into main context is budget spent on noise.
- Batch independent calls in parallel: issue fetch + repo exploration, multi-file reads, `gh pr checks` + comment fetches in Phase 8.
- Verification is adversarial by default: reviewers get the artifact (diff, AC list), never your reasoning, and are asked to refute rather than confirm.
- When your judgment and the ticket conflict mid-implementation, escalate with a recommendation; do not silently follow either.

## Decision log (autonomous runs only)

Append to `outputs/<issue-id-lowercase>/ship-log.md` in the sandbox repo (gitignored). One decision per line, ~120 chars max, for fast skim: `HH:MM <subject>: <one-line reason>`. Examples:

- `14:02 plan: split into 3 tasks because AC has 3 distinct outcomes`
- `14:18 tests: chose vitest (already in repo); 4 tests, one per AC`
- `15:10 review: addressed CodeRabbit nit on naming; ignored the 80-col one (codebase uses 100)`

At the end of the run, print the log's absolute path so it is clickable in Nex.

## Escalation

Stop the autonomous flow and report when: a Phase 2 blocker appears (ticket-vs-repo mismatch, contradictory AC, missing repo); the test loop (4b) or CI loop (7) hits its 5-iteration cap; the self-audit (5b) finds unfixable blockers; a reviewer raises substantive disagreement; or the 30-minute review window elapses without approval.

The escalation message must include: where you stopped, what you tried, your blocker hypothesis, and the absolute path to the decision log. Take no further action (especially no merge) until the user responds.
