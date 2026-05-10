---
name: linear-do
description: "Implement a Linear issue end-to-end: read the ticket, code, commit, open a PR, monitor CI. Use for do/implement/work on a Linear issue, or when given a Linear URL/ID with intent to implement. Includes an autonomous 'ship' mode that runs to merge without checkpoints (triggered by 'ship', 'ship the ticket', 'autonomously', '--auto')."
---

# Linear Do

Implement a Linear issue end-to-end: read the ticket, make the changes, commit, open a PR, and monitor CI until green.

## Operating modes

- **Interactive** (default): pause at Phase 2 for clarifying questions, ask before marking ready/merging. Follow the numbered Workflow below as written.
- **Autonomous** (opt-in): end-to-end ticket-to-merge without checkpoints. Triggered when the user says "ship", "ship the ticket", "ship-it", "autonomously", "end-to-end", or passes `--auto`. Follow the numbered Workflow but apply the deltas in the "Autonomous mode" section near the end of this file. In autonomous mode, write a decision log throughout (see "Decision log" section).

## Input

The user provides a Linear issue URL or identifier. Examples:

- `https://linear.app/mr-yum/issue/CUSM-642/some-title`
- `CUSM-642`

Extract the issue identifier from the URL if a full URL is given.

## Workflow

### Phase 1: Understand the Issue

1. **Fetch the issue** using `mcp__claude_ai_Linear__get_issue` (preferred) or `linear issue view <ID>`.
2. Read the full description, acceptance criteria, implementation guidance, and any comments.
3. **Capture the git branch name** returned by the Linear API. This is Linear's auto-generated branch name (e.g. `feature/cusm-642-remove-db-schema-compat-matrix-and-narrow-peer-range-to-v14`). Use this as the branch name in Phase 3.
4. Identify:
   - What needs to change and why
   - Scope boundaries (in scope vs out of scope)
   - Acceptance criteria and verification steps
   - Risk tier and any constraints
   - Files likely involved

### Phase 2: Ask Questions

Before writing any code, **ask the user** about anything that is unclear or ambiguous. Good questions to consider:

- Which repository or working directory should the changes be made in?
- Are there acceptance criteria or verification steps not captured in the ticket?
- Are there scope boundaries that are unclear?
- **Worktree or branch?** Ask if the user wants to work in a git worktree (isolated copy of the repo) or switch branches in the current working directory. Default to the current directory if the user has no preference.
- Any environment setup needed?

Do not proceed until the user confirms you have enough context.

### Phase 3: Set Up

1. Confirm you are in the correct repository/directory.
2. Ensure the working tree is clean (`git status`). If there are uncommitted changes, ask the user how to handle them.

**Branch name:** Use the git branch name returned by the Linear API in Phase 1 (e.g. `feature/cusm-642-remove-db-schema-compat-matrix-and-narrow-peer-range-to-v14`). If the API did not return one, fall back to `feature/<issue-id-lowercase>-short-description` or `fix/<issue-id-lowercase>-short-description`.

**If using a worktree:**

1. From the repo root, create a worktree: `git worktree add ../<repo-name>-<issue-id> -b <branch-name> main`
2. `cd` into the worktree directory.
3. Pull latest: `git pull origin main` (the worktree already tracks main as its start point).
4. Continue all subsequent phases inside the worktree directory.
5. After the PR is merged (or if the user abandons the work), clean up: `git worktree remove ../<repo-name>-<issue-id>`.

**If using a branch (default):**

1. Pull the latest main: `git checkout main && git pull`
2. Create and switch to the feature branch: `git checkout -b <branch-name>`

### Phase 4: Implement

1. Make the changes described in the issue.
2. Follow existing code patterns and conventions in the repository.
3. Run any verification commands listed in the issue (typecheck, lint, tests).
4. If verification fails, fix the issues before proceeding.

### Phase 5: Commit

Use the **git-commit** skill to generate and create the commit.

- Stage all relevant changed files.
- The skill will generate a conventional commit message from the diff.
- The branch name includes the issue code, so the skill will handle prefixing.

### Phase 6: Create PR

Use the **gh-pr** skill to generate and create the pull request.

- The skill will generate a PR title and body from the branch's changes against main.
- The PR is created as a draft by default.
- The skill will push the branch and create the PR via `gh`.

### Phase 7: Monitor CI

After the PR is created, check that CI passes:

1. Run `gh pr checks <number>` to see the status of checks.
2. If checks are still pending, set up a `/loop` to poll every 3 minutes:
   - Run `gh pr checks <number>` each iteration.
   - If all checks pass, report success and stop the loop.
   - If any checks fail, use the **bk-buildkite** skill to investigate Buildkite failures. Run `bk use mryum`, then `bk build view <build-number> -p <pipeline> -s failed,broken` to find the failed job, then `bk job log <job-uuid> -p <pipeline> --no-timestamps` to read the logs. Fix the issues, commit the fix (using git-commit skill), push, and continue monitoring.
3. Once all checks are green, notify the user and ask if they want to:
   - Mark the PR as ready for review (`gh pr ready <number>`)
   - Request reviewers
   - Enable auto-merge
   - Update the Linear issue status

## Guidelines

- Always read the full issue before asking questions or starting work.
- Do not start implementing until the user confirms you have enough context.
- Follow existing code patterns in the repository; do not introduce new conventions.
- Keep changes scoped to what the issue describes. Do not refactor adjacent code.
- If the issue is ambiguous or underspecified, ask rather than guess.
- If implementation reveals the issue needs a spike or is more complex than expected, stop and discuss with the user.
- Use MCP Linear tools when available, fall back to `linear` CLI if not.

## Autonomous mode

When the user invokes this skill with autonomous intent, apply the following deltas to the Workflow above. Defaults below are the autonomous defaults; they replace the interactive choices.

### Phase 1 (Understand) — additions

- Capture acceptance criteria as an explicit list. Each AC becomes a target for tests in Phase 4b.
- Capture the verification commands listed in the ticket (lint, typecheck, test). These define "green" later.

### Phase 2 (Ask Questions) — skip

Skip the user-facing question phase entirely. Use sensible defaults:

- Repository: the one Linear's git URL points at (or, if Paul ran the skill from inside a repo, that repo).
- Worktree: yes (mandatory in autonomous mode).
- Scope: exactly what the ticket describes; no opportunistic refactors.

If a true blocker appears (e.g. ticket references a repo you cannot find, or AC contradicts itself), stop and escalate (see "Escalation"). Do not invent answers.

### Phase 3 (Set Up) — mandatory worktree

Always use a worktree. Pattern: `git worktree add ../<repo>-<issue-id-lowercase> -b <branch-name> main`, then `cd` into it. Skip the "if branch / if worktree" choice in the interactive instructions.

### Phase 4 (Implement) — plan first with TaskCreate

Before editing any code:

1. Create a TaskCreate task list. One task per acceptance criterion, plus one task per file you expect to change. Mark each `in_progress` when you start it and `completed` when done.
2. Implement against the plan. If you discover the plan was wrong, update the tasks rather than silently diverging.

### Phase 4b (new) — acceptance-criteria test loop

After implementation, before commit:

1. Identify the test framework already in use (read `package.json`, `pyproject.toml`, etc. — do not introduce a new framework).
2. For each acceptance criterion, write or update at least one test that exercises the AC. If an AC is fundamentally untestable (e.g. "looks better"), record that decision in the log and skip.
3. Run the test command. If failures:
   - Read the failure output, fix the underlying issue, re-run.
   - **Iteration cap: 5.** After the 5th failed iteration, stop and escalate. Provide failing test names, your fix attempts, and your hypothesis about the blocker.
4. Also run any verification commands the ticket listed (typecheck, lint). All must pass before proceeding.

### Phase 5 (Commit) — same

Use the **git-commit** skill as in interactive mode.

### Phase 5b (new) — self-audit before PR

Before invoking gh-pr, spawn a subagent (`subagent_type: general-purpose`) with a prompt that audits the current diff against the **gh-pr** skill's requirements. The subagent must check:

- Branch name carries the issue code in a parseable form (`feature/<id>-...` or `fix/<id>-...`).
- A PR template exists at `.github/pull_request_template.md`. If it does, identify any sections that the upcoming PR description would need to fill.
- Every commit message on the branch follows conventional-commit format.
- No remaining placeholder text (TODO, FIXME, `xxx`, lorem ipsum) in the diff.
- Australian spelling in code comments and strings the user will see.

The subagent returns a structured findings list. If any blocker is reported, fix it (or, for spelling/comment-only nits, accept and document in the log). Then proceed to Phase 6.

### Phase 6 (Create PR) — same

Use the **gh-pr** skill as in interactive mode. Note the PR number it returns.

### Phase 7 (Monitor CI) — extended

Same as interactive, with two changes:

- After CI is green, **do not** ask the user about marking ready / requesting reviewers / auto-merge. Mark ready automatically: `gh pr ready <number>`, then proceed to Phase 8.
- CI fix-loop iteration cap: 5. After the 5th failed CI run, escalate.

### Phase 8 (new) — review feedback loop

1. Poll for review activity every 5 minutes (max 30 minutes total). Use `/loop` for the polling.
2. Each iteration, read:
   - `gh pr view <number> --comments` for inline + general comments (CodeRabbit posts here).
   - `gh pr view <number> --json reviews` for review-state changes.
3. For each new comment since the previous iteration:
   - **Actionable + clearly correct**: implement the change, commit (via git-commit skill), push.
   - **Stylistic / nit you disagree with**: post a brief polite reply explaining your reasoning. Do not silently ignore.
   - **Substantive disagreement** (e.g. reviewer wants a different approach to the AC): stop and escalate. Do not unilaterally rewrite.
4. Exit the loop when: an approving review lands AND CI is green, OR 30 minutes elapse.

### Phase 9 (new) — merge and archive

Once approved + green:

1. Verify all required checks: `gh pr checks <number>`.
2. Squash-merge: `gh pr merge <number> --auto --squash`.
3. After merge confirms, archive the worktree: `git worktree remove ../<repo>-<issue-id-lowercase>`.
4. Update the Linear ticket to the team's "Done" / equivalent state. For Clean Kitchen task force, use the state IDs already in MEMORY.md (`Linear CKTF Team State IDs`). For other teams, look up the state via `mcp__claude_ai_Linear__get_team`.

## Decision log

For autonomous runs only. Append decisions to `outputs/<issue-id-lowercase>/ship-log.md` in the sandbox repo (the path is gitignored).

Format: one decision per line. `HH:MM <subject> — <one-line reason>`. Examples:

- `14:02 plan — split into 3 tasks because AC has 3 distinct outcomes`
- `14:18 tests — chose vitest (already in repo); 4 tests, one per AC`
- `14:45 audit — 1 blocker (missing risk classification in PR body); fixed`
- `15:10 review — addressed CodeRabbit nit on naming; ignored the 80-col one (codebase uses 100)`
- `15:24 merge — squashed and removed worktree`

Cap at ~120 chars per line. The log is for fast skim, not narrative.

At the end of the run, output the absolute path to the log so it's clickable in Nex.

## Escalation

Stop the autonomous flow and report to the user when any of these happen:

- Phase 2 hits a true blocker (ticket-vs-repo mismatch, contradictory AC, missing repo).
- Test loop hits its 5-iteration cap (Phase 4b).
- Self-audit returns blockers that cannot be fixed automatically (Phase 5b).
- CI fix-loop hits its 5-iteration cap (Phase 7).
- A reviewer raises substantive disagreement (Phase 8).
- 30-minute review window elapses without approval (Phase 8).

Escalation message must include: where you stopped, what you tried, what you think the blocker is, and the absolute path to the decision log. Do not auto-merge or take further action until the user responds.
