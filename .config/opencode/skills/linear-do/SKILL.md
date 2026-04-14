---
name: linear-do
description: "Implements a Linear issue end-to-end: reads the issue, implements the changes, commits, creates a PR, and monitors CI. Use when asked to do, implement, build, or work on a Linear issue. Triggers on phrases like 'do this Linear issue', 'implement CUSM-123', 'work on this Linear ticket', or when a Linear issue URL is provided with intent to implement it."
---

# Linear Do

Implement a Linear issue end-to-end: read the ticket, make the changes, commit, open a PR, and monitor CI until green.

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

Use the **write-commit-message** skill to generate and create the commit.

- Stage all relevant changed files.
- The skill will generate a conventional commit message from the diff.
- The branch name includes the issue code, so the skill will handle prefixing.

### Phase 6: Create PR

Use the **write-pull-request** skill to generate and create the pull request.

- The skill will generate a PR title and body from the branch's changes against main.
- The PR is created as a draft by default.
- The skill will push the branch and create the PR via `gh`.

### Phase 7: Monitor CI

After the PR is created, check that CI passes:

1. Run `gh pr checks <number>` to see the status of checks.
2. If checks are still pending, set up a `/loop` to poll every 3 minutes:
   - Run `gh pr checks <number>` each iteration.
   - If all checks pass, report success and stop the loop.
   - If any checks fail, use the **bk-buildkite** skill to investigate Buildkite failures. Run `bk use mryum`, then `bk build view <build-number> -p <pipeline> -s failed,broken` to find the failed job, then `bk job log <job-uuid> -p <pipeline> --no-timestamps` to read the logs. Fix the issues, commit the fix (using write-commit-message skill), push, and continue monitoring.
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
