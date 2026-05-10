---
name: adversarial-review
description: "Adversarial PR review: trace each acceptance criterion against the diff, hunt for bugs/regressions/missing edge cases, return a single verdict (CLEAN | NITPICKS_ONLY | CHANGES_REQUESTED), archive to sandbox/reviews/<pr>.md, and post inline comments only on explicit user approval. Use on `/adversarial-review`, 'adversarial review', 'hostile review', or when given a PR number/URL with intent to challenge it."
---

# Adversarial PR Review

Hostile-by-default code review. Assume the diff is wrong until each acceptance criterion is proven satisfied. Output a single verdict, archive the review, and only post to GitHub when the user explicitly says so.

This is distinct from `reviewing-branch-changes` (principal-engineer review of the working tree) and `pr-review-orchestrator` (multi-agent fan-out). Use this skill when you want one focused adversarial pass with a clear go/no-go verdict.

## Inputs

The user invokes this on a PR number, URL, or branch:

- `42` → current repo, PR #42
- `https://github.com/<org>/<repo>/pull/42`
- (no arg) → current branch's open PR via `gh pr view --json number,url,headRefOid,baseRefName,body,title`

Resolve at the start of the run:

```
PR_NUMBER=<from input>
PR_DATA=$(gh pr view "$PR_NUMBER" --json number,url,headRefOid,baseRefName,body,title,files)
```

If `gh pr view` fails (no PR for current branch, wrong repo), tell the user and stop. Don't guess.

## Workflow

### Step 1: Pull diff and ACs

1. Fetch the diff: `gh pr diff "$PR_NUMBER"`. For very large PRs (>2000 lines), also `gh pr view "$PR_NUMBER" --json files` to triage by file.
2. Extract acceptance criteria from the PR body. Look for, in this order:
   - A `## Acceptance criteria` / `## ACs` / `## Requirements` section.
   - Linked Linear/Jira ticket in the PR body — fetch it (`mcp__claude_ai_Linear__get_issue` for Linear) and pull ACs from there.
   - Checkbox lists in the PR body (`- [ ]` / `- [x]`).
3. If no ACs are findable, ask the user for them once. Don't proceed without an AC list — adversarial review without targets is just nitpicking.

### Step 2: Trace each AC against the diff

For every AC, write down:

- **Where in the diff is this implemented?** (file:line, or "not implemented").
- **What proves it works?** (test that exercises it, or "no test").
- **What inputs would break it?** (edge cases, malformed data, race conditions, off-by-one, null/undefined, large payloads).

If an AC has no diff evidence, that's a `CHANGES_REQUESTED` finding.

### Step 3: Adversarial pass

Hunt actively, not passively. Run each lens against the changed code:

- **Bugs**: off-by-one, null/undefined deref, wrong comparator (`==` vs `===`, `<` vs `<=`), inverted boolean, swapped args, mutation of inputs, async without await, missing return, fallthrough cases.
- **Regressions**: removed validation, loosened types, removed test, weakened assertion, behavior change in a shared helper used elsewhere (grep callers of changed exports).
- **Missing edge cases**: empty array, single element, max size, unicode/emoji, timezone boundaries, concurrent calls, partial failure, retry semantics, idempotency.
- **Security**: input not sanitized, auth check bypassed, secrets in logs, SQL/command injection, XSS surface, missing rate limit on a new endpoint.
- **Data integrity**: migration without rollback, schema change without backfill plan, money math in float, non-atomic multi-write, missing index on new query path.
- **Test quality**: snapshot-only assertions, mocked-away the thing under test, flaky timer/network, no negative case, no boundary case.

For each finding, capture: file, line, what's wrong, why it matters, smallest fix.

### Step 4: Decide the verdict

Pick exactly one. Be honest — verdict inflation defeats the point.

- **`CLEAN`** — every AC traced to working code with test coverage; no bugs, regressions, or missing edge cases worth raising. Allowed to ship as-is.
- **`NITPICKS_ONLY`** — ACs satisfied; only style/polish/non-blocking suggestions remain. Author can ship without addressing them, or address at their discretion.
- **`CHANGES_REQUESTED`** — at least one of: an AC isn't satisfied, a bug/regression is present, a missing edge case has realistic impact, or test coverage is insufficient for the risk. Must be fixed before merge.

If you're hesitating between two verdicts, pick the stricter one and explain why.

### Step 5: Write the review file

Save to `/Users/paul/dev/sandbox/reviews/pr-<PR_NUMBER>-<YYYY-MM-DD>.md`. Create `reviews/` if it doesn't exist.

If today's date isn't in context, run `date +%Y-%m-%d`.

Template:

```markdown
# Adversarial Review — PR #<num>: <title>

- URL: <pr url>
- Head: <short sha>
- Base: <branch>
- Reviewed: <YYYY-MM-DD>

## Verdict: <CLEAN | NITPICKS_ONLY | CHANGES_REQUESTED>

<one-sentence justification>

## Acceptance criteria trace

- [x] **AC1**: <text> — implemented at `path/to/file.ts:42`, covered by `path/to/file.test.ts:88`.
- [ ] **AC2**: <text> — **not implemented**. <where it should live, what's missing>.
- [x] **AC3**: <text> — implemented at `...`, **no test** — see finding REV-3.

## Findings

### `REV-1` blocking — `path/to/file.ts:42`

<issue statement>

Why this matters: <1-3 sentences>.

Repro/edge case: <input that breaks it, or "covered by test X but assertion is weak">.

Recommended change:
\`\`\`ts
// minimal fix
\`\`\`

### `REV-2` suggestion — `path/to/other.ts:88`

...

### `REV-3` nitpick — `path/to/file.test.ts:88`

...

## Open questions

- <thing the diff didn't make clear; ask the author>

## Notes

- <anything the author should know that isn't a finding: design choice you'd flag in a 1:1, related cleanup, etc.>
```

Severity ordering inside Findings: `blocking` → `suggestion` → `question` → `nitpick`. Within a severity, order by file then line.

After writing, print the absolute path of the review file.

### Step 6: Offer to post

After writing the file, ask the user once:

> "Verdict: `<verdict>`. <N> blocking, <M> suggestions, <K> nitpicks. Want me to post inline comments on the PR? (yes / blocking only / no)"

- **`yes`** — post every finding (excluding nitpicks unless the user opts in) using the inline-comment flow below.
- **`blocking only`** — post only `blocking` findings.
- **`no`** — stop. The archived file is the deliverable.

Never post without explicit approval. Never auto-approve or request-changes via `gh pr review` — only inline comments.

## Posting inline comments

Use `gh api repos/<org>/<repo>/pulls/<num>/comments`. For each finding to post:

1. Resolve repo from `gh pr view --json url` and head sha from `headRefOid`.
2. Confirm the line number matches the changed-side line in the diff (`gh pr diff` or `git diff`).
3. Build the body in a temp file (avoid shell-quoting issues with backticks/code blocks):
   - Body format: short issue line, then `Why this matters:`, then `Recommended change` with a fenced code block.
   - No `<details>` wrapper, no severity prefix label inside the body — the finding ID and severity live in the archived file.
4. Serialize to JSON:
   ```bash
   node -e "const fs=require('fs'); const body=fs.readFileSync('/tmp/rev.md','utf8'); fs.writeFileSync('/tmp/rev.json', JSON.stringify({ body, commit_id: '<sha>', path: '<file>', line: <n>, side: 'RIGHT' }));"
   ```
5. POST: `gh api repos/<org>/<repo>/pulls/<num>/comments -X POST --input /tmp/rev.json`.
6. If the finding doesn't anchor to a changed line in the diff hunk, post as file-level (`subject_type: "file"`, omit `line`/`side`) and include the relevant lines as a fenced block in the body.
7. After posting, capture the returned `html_url` for each comment and report all URLs back to the user.

## Notes

- Australian spelling.
- Hostile-by-default tone in your reasoning, neutral-professional tone in posted comments. Don't ship sneering comments to GitHub.
- Don't waive a finding because the legacy code does the same thing. Note the legacy issue separately if it matters.
- If the PR description has no ACs and the user can't provide them, downgrade to `reviewing-branch-changes` instead — adversarial review needs targets.
- The review file is the source of truth. If the user later asks "what did we find on PR 42?", read the archived file rather than re-running.
