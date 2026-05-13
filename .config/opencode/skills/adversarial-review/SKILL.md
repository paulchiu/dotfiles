---
name: adversarial-review
description: "Adversarial PR review: trace each acceptance criterion against the diff, hunt for bugs/regressions/missing edge cases, return a single verdict (CLEAN | NITPICKS_ONLY | CHANGES_REQUESTED), archive a decision doc to ~/dev/sandbox, and post inline comments only on explicit user approval. Use on `/adversarial-review`, 'adversarial review', 'hostile review', or when given a PR number/URL with intent to challenge it."
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

### Step 5: Write the decision doc

Default location: `~/dev/sandbox/`. `/tmp/` is also acceptable for throwaway runs. The doc is a decision aid (a checklist of actions the user can take on the PR), not just a findings dump.

Filename convention (user's global rule, see `~/.claude/CLAUDE.md`):

- `yyyy-mm-dd Title.md`, preserving acronym casing.
- Example: `2026-05-13 PR 2590 adversarial review.md`.
- If today's date isn't in context, run `date +%Y-%m-%d`.

After writing, print the absolute path of the file (the nex terminal only renders previews/click-to-open on full paths).

Template:

```markdown
# Adversarial Review, PR #<num>: <title>

- URL: <pr url>
- Head: <short sha>
- Base: <branch>
- Reviewed: <YYYY-MM-DD>

## Verdict: <CLEAN | NITPICKS_ONLY | CHANGES_REQUESTED>

<one-sentence justification>

## Possible actions

Tick the actions you want to take. The skill will execute the ticked ones on request.

- [ ] Post REV-1 inline (`path/to/file.ts:42`, blocking)
- [ ] Post REV-2 inline (`path/to/other.ts:88`, suggestion)
- [ ] Post REV-3 inline (`path/to/file.test.ts:88`, nitpick)
- [ ] Approve the PR (`gh pr review --approve`)
- [ ] Request changes (`gh pr review --request-changes`)
- [ ] Leave a top-level summary comment instead of inline
- [ ] Ask the author the open questions below
- [ ] No action; archive only

## Acceptance criteria trace

- [x] **AC1**: <text>, implemented at `path/to/file.ts:42`, covered by `path/to/file.test.ts:88`.
- [ ] **AC2**: <text>, **not implemented**. <where it should live, what's missing>.
- [x] **AC3**: <text>, implemented at `...`, **no test**, see finding REV-3.

## Findings

### `REV-1` blocking, `path/to/file.ts:42`

<issue statement>

Why this matters: <1-3 sentences>.

Repro/edge case: <input that breaks it, or "covered by test X but assertion is weak">.

Recommended change:
\`\`\`ts
// minimal fix
\`\`\`

### `REV-2` suggestion, `path/to/other.ts:88`

...

### `REV-3` nitpick, `path/to/file.test.ts:88`

...

## Open questions

- <thing the diff didn't make clear; ask the author>

## Notes

- <anything the author should know that isn't a finding: design choice you'd flag in a 1:1, related cleanup, etc.>
```

Severity ordering inside Findings: `blocking` → `suggestion` → `question` → `nitpick`. Within a severity, order by file then line. Mirror that ordering in the Possible actions list.

### Step 6: Offer the action checklist

After writing the file, surface the same Possible-actions list inline in chat so the user can tick without opening the file. Phrase it as a single question:

> "Verdict: `<verdict>`. <N> blocking, <M> suggestions, <K> nitpicks. Decision doc at `<absolute path>`. Which actions should I take?"
>
> - [ ] Post REV-1 inline
> - [ ] Post REV-2 inline
> - ...
> - [ ] Approve the PR
> - [ ] Request changes
> - [ ] No action

The user replies with the items they want executed (or "all", "blocking only", "nitpicks only", "approve and post all", etc.).

Never post or approve/request-changes without explicit user instruction in this turn. A prior session's approval doesn't carry over.

## Posting inline comments

Use `gh api repos/<org>/<repo>/pulls/<num>/comments`. For each finding to post:

1. Resolve repo from `gh pr view --json url` and head sha from `headRefOid`.
2. Confirm the line number matches the changed-side line in the diff (`gh pr diff` or `git diff`).
3. Write the body to a temp file. **Use a non-`.md` extension** (e.g. `/tmp/rev-1.body` or `.txt`) so Prettier-style Write hooks don't reformat code snippets inside the body (single quotes get converted to double quotes, semicolons added, etc.). Prefer `cat > /tmp/rev-N.body <<'BODY' ... BODY` via Bash for the same reason.
4. Serialize to JSON:
   ```bash
   node -e "const fs=require('fs'); const body=fs.readFileSync('/tmp/rev-1.body','utf8'); fs.writeFileSync('/tmp/rev-1.json', JSON.stringify({ body, commit_id: '<sha>', path: '<file>', line: <n>, side: 'RIGHT' }));"
   ```
5. POST: `gh api repos/<org>/<repo>/pulls/<num>/comments -X POST --input /tmp/rev-1.json --jq '{html_url, path, line}'`.
6. If the finding doesn't anchor to a changed line in the diff hunk, post as file-level (`subject_type: "file"`, omit `line`/`side`) and include the relevant lines as a fenced block in the body for context.
7. After posting, capture the returned `html_url` for each comment and report all URLs back to the user.

## Comment style

Use this wrapper for every posted comment (mirrors the `reviewing-branch-changes` GitHub Draft Mode wrapper so the two skills produce visually consistent comments):

````md
LLM note: <one-line short version, non-redundant with the opening paragraph>

<details>
  <summary>LLM reasoning</summary>

<plain opening paragraph stating the issue and the expected fix direction; no severity label>

Why this matters: 1-3 sentences on concrete impact.

Recommended change

```<lang>
// minimal fix sketch or exact replacement
```

Patch-style diff (optional)

```diff
- old line(s)
+ new line(s)
```

Current code (optional)

```<lang>
// 3-12 lines from the changed code near the target line
```

References (optional)

- [Changed line link](https://github.com/<org>/<repo>/blob/<head-sha>/path/to/file.ts#L<line>)
</details>
````

Rules:

- Plain markdown only inside the body, with `<details>` / `<summary>` as the outer wrapper.
- Start with `LLM note:` on the first line; opening paragraph follows the `<summary>` directly, with no `Suggestion:` / `Blocking:` / `Nitpick:` / `Question:` prefix.
- The finding ID (e.g. `REV-1`) and severity live in the archived decision doc, not in the GitHub comment body.
- If the user supplies their own framing text, prepend `My note: <text>` above the `LLM note:` line.
- Code snippets must match the target project's style (single vs double quotes, semicolons, formatting). Read at least one nearby file in the changed code before drafting snippets so house style is preserved.
- Australian spelling. Neutral-professional tone in posted comments, even when the internal reasoning was hostile.

## Approving or requesting changes

Only when the user explicitly ticks the "Approve" or "Request changes" action:

```bash
gh pr review <PR_NUMBER> --repo <org>/<repo> --approve --body "<short summary>"
# or
gh pr review <PR_NUMBER> --repo <org>/<repo> --request-changes --body "<short summary>"
```

### Review body style

Keep the review-level body **ultra-terse: one short sentence, ~10 words**. It's a vibe-check on top of the inline comments, not a restatement. Do **not** recap findings, AC trace, test counts, or repeat what's already in the inline comments. The reader is about to scroll the inline thread anyway.

Pattern: `<one-line sentiment>, <brief tally of inline findings>.`

Examples (match this register, casual abbreviations like "LGTM" are fine):

- `LGTM, just one change requested and a nit pick.`
- `Looks good, two nit picks inline.`
- `One blocker inline, see REV-1.`
- `Ship it.` (for `--approve` with nothing to flag)

Tone rules: no em dashes (commas, colons, or separate sentences instead); Australian spelling; "nit pick" as two words to match the user's voice.

Avoid: "Adversarial review: bug fix is correct and all 5 ACs satisfied…", lists of findings with file paths, test counts, or any sentence longer than the inline-comment summary.

Verify the review was recorded:

```bash
gh pr view <PR_NUMBER> --repo <org>/<repo> --json reviews \
  --jq '.reviews[-3:] | map({author: .author.login, state, submittedAt})'
```

Never approve as a default; the user must explicitly authorise it in the current turn.

## Notes

- Hostile-by-default tone in your reasoning, neutral-professional tone in posted comments. Don't ship sneering comments to GitHub.
- Don't waive a finding because the legacy code does the same thing. Note the legacy issue separately if it matters.
- If the PR description has no ACs and the user can't provide them, downgrade to `reviewing-branch-changes` instead, adversarial review needs targets.
- The decision doc is the source of truth. If the user later asks "what did we find on PR 42?", read the archived file rather than re-running the review.
