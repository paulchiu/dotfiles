---
name: pr-review-orchestrator
description: "Multi-perspective PR review orchestrator. Runs the review-code skill as a baseline, then fans out 4 specialised perspectives (security, performance, acceptance-criteria, style) in parallel via codex or Claude subagents (user picks at invocation), aggregates findings into a single verdict, and posts inline comments via gh. Use for: multi-perspective review, fan-out review, orchestrated PR review, review with all perspectives."
---

# PR Review Orchestrator

Combine a `review-code` baseline with four specialist perspectives (plus optional CodeRabbit), aggregate and deduplicate, post inline comments. Only escalate to the user on a blocker or reviewer disagreement.

## Input

PR identifier: `123` (current repo), `mr-yum/<repo>#123`, or a full GitHub PR URL. If none given, use the current branch's PR (`gh pr view --json number,url`).

## Phase 0: Pick the runtime

Ask the user before proceeding past Phase 1, capture as `RUNTIME`, `CODERABBIT`, `AUTO_POST`:

- Run perspectives via **codex** (parallel `codex:codex-rescue` agents) or **Claude** (parallel `general-purpose` agents)?
- Run CodeRabbit in parallel? (default: yes if the repo is wired for it; skip on auth error)
- Auto-post comments after aggregation, or stop at the decisions doc? (default: stop)

## Phase 1: Gather PR context

Run in parallel:

```
gh pr view <pr> --json number,url,title,body,headRefOid,headRefName,baseRefName,headRepository,baseRepository,files,additions,deletions
gh pr diff <pr>
```

Extract any Linear ticket ID from the PR body or branch name (e.g. `CAD-1709`, `CUSM-642`); if found, fetch it via `mcp__claude_ai_Linear__get_issue` for acceptance criteria and scope.

Capture for the session: `PR_NUMBER`, `PR_URL`, `HEAD_SHA`, `HEAD_BRANCH`, `BASE_BRANCH`, `OWNER/REPO`, changed files, Linear ticket text.

A local checkout is not required: reviewers read the diff via `gh pr diff` and individual files via `gh api repos/<owner>/<repo>/contents/<path>?ref=<sha>`. Ask before running `gh pr checkout`.

## Phase 2: Baseline review

Run the `review-code` skill as the shared baseline all perspectives build on. It produces the canonical finding checklist with stable IDs, severity, and file:line targets.

- **Local checkout available:** invoke `review-code` directly against `<base>...HEAD`.
- **PR-only mode:** spawn one `general-purpose` agent with the `review-code` skill loaded, briefed with the PR metadata, full `gh pr diff` output, the Linear ticket, and instructions to follow that skill's contract verbatim (checklist with stable IDs included).

Save to `outputs/pr-reviews/<owner>-<repo>-<pr>/<yyyy-mm-dd>/00-baseline.md`. Every perspective references baseline finding IDs (e.g. `BASE-DT-1`) when they agree, extend, or disagree.

## Phase 3: Fan out four perspectives in parallel

Spawn all four in a single message (`run_in_background: true`) so they run concurrently. Subagent type per `RUNTIME`: `codex:codex-rescue` or `general-purpose`.

### Shared brief (every perspective gets this)

```
You are the <PERSPECTIVE> reviewer for <OWNER/REPO>#<PR_NUMBER>.

PR: <PR_URL>
Branch: <HEAD_BRANCH> @ <HEAD_SHA>
Base: <BASE_BRANCH>
Linear ticket (if any): <ID>, acceptance criteria pasted below.

You DO NOT start from scratch. The baseline review is at:
  outputs/pr-reviews/<key>/<date>/00-baseline.md

Read the baseline first. For each baseline finding inside your perspective:
- Confirm (cite finding ID, agree)
- Extend (add detail or evidence the baseline missed)
- Downgrade/Disagree (explain why the baseline is wrong from this perspective)

Then add NEW findings specific to your perspective, in the review-code finding format:
- Stable ID prefixed with your perspective (SEC-1, PERF-1, AC-1, STYLE-1)
- file:line target
- severity (blocking | suggestion | question | nitpick)
- 1-3 sentence rationale
- recommended fix (concrete, not abstract)

Output format:
## Perspective: <PERSPECTIVE>
### Verdict: BLOCK | NITPICKS_ONLY | CLEAN
### Baseline reactions
- BASE-XX-1: confirm | extend | disagree, <reason>
### New findings
- <ID> file:line, severity, summary; fix: ...
### Notes
- Anything you investigated but ruled out, 1 line each.

Save your output to:
  outputs/pr-reviews/<key>/<date>/0<n>-<perspective>.md

Diff is pasted below; read individual files via:
  gh api repos/<owner>/<repo>/contents/<path>?ref=<HEAD_SHA>
```

### Per-perspective addenda

Append exactly one per agent:

**security-reviewer (`01-security`)**
> Focus: authn/authz, input validation, injection (SQL/HTML/shell), secrets handling, PII exposure, payment safety, SSRF, deserialisation, dependency CVEs introduced by package changes, CSRF, race conditions in security-critical paths, log injection. Treat payment/PII/auth changes as high-risk and require very high confidence. Ignore non-security issues unless they enable a security one.

**performance-reviewer (`02-performance`)**
> Focus: N+1 queries, missing indexes / migration safety, unnecessary `Promise.all` over serial work, blocking CPU work in request handlers, large payloads, memoisation gaps, render thrash on the FE, list virtualisation, bundle-size hits from new deps, Tailwind class explosion, expensive regexes. Quote concrete evidence (line + caller). Ignore non-perf issues.

**acceptance-criteria-reviewer (`03-acceptance-criteria`)**
> Focus: trace each AC from the linked Linear ticket against the diff. Map AC to the file:line that fulfils it, or flag as MISSING. Also flag scope drift (changes not justified by an AC) and behaviour changes that contradict ACs. If no Linear ticket exists, derive ACs from the PR description and flag the absence of a ticket as a `question`. Be explicit: "AC1 fulfilled at <file:line>", "AC3 MISSING: no implementation found".

**style-reviewer (`04-style`)**
> Focus: team conventions in `references/team-pr-references.md` and `references/other-team-pr-preferences.md` from the review-code skill: naming, logging strings, feature flag style, Promise handling, money math, DAO patterns, FE conventions, Tailwind tokens, TypeScript `any`/non-null assertions, comment hygiene per Paul's CLAUDE.md (no em dashes, JSDoc blocks). Ignore correctness/security/perf issues unless they violate a written convention.

### CodeRabbit (optional, parallel)

If `CODERABBIT == yes`, run backgrounded so it overlaps the perspectives:

```
coderabbit review --plain --type committed --base <BASE_BRANCH>
```

On auth or network failure, surface and continue without it.

## Phase 4: Aggregate

Once all perspective files exist (and CodeRabbit if used), write `outputs/pr-reviews/<key>/<date>/aggregate.md`:

1. **Deduplicate by `file:line + intent`.** Same line, same reason: keep one finding, note `also flagged by: <perspectives>`. Different concerns at the same line stay separate.
2. **Resolve conflicts.** Severity disagreement: take the highest. Validity disagreement: surface under "Disagreements", never silently drop.
3. **Global IDs** (`PR<n>-AGG-1` ...) with back-references to the original perspective IDs.
4. **Verdict:** `BLOCK` if any finding is `blocking`; `NITPICKS_ONLY` if only `nitpick` and `question` findings remain; otherwise `CLEAN`.
5. **Group by severity**, then file diff order.

Include: verdict, disagreements (these are the user-ping triggers), findings table (global ID, file:line, severity, summary, fix sketch, source perspectives, baseline ID), and a short reasoning trace per perspective ("security: focused on the new webhook handler; ruled out CSRF because ...") so the user can audit each agent.

## Phase 5: Decisions doc

Write the canonical doc to `outputs/pr-reviews/<key>/<date>/decisions.md`:

```md
# PR Review Decisions: <OWNER/REPO>#<PR>

- PR: <PR_URL>
- Reviewed: <date> @ <HEAD_SHA>
- Runtime: codex | claude
- CodeRabbit: yes/no
- Verdict: <verdict>

## Per-reviewer reasoning
### security
<1 paragraph: what they looked at, ruled out, flagged>
### performance / acceptance-criteria / style / coderabbit (if run)
...

## Disagreements
<list, or "None">

## Final findings
<from aggregate.md>

## Action
- [ ] Comments posted to GitHub: <yes/no, list URLs>
- [ ] User ping required: <yes/no, only yes if BLOCK or disagreements>
```

## Phase 6: Post inline comments (only if `AUTO_POST == yes`)

Post via `gh api` per the review-code skill's `references/posting.md` recipe: one inline comment per finding anchored to the changed line in the diff hunk, file-level comment when no anchor exists. Include the global aggregate ID in each comment. Skip `nitpick` findings unless the user explicitly asks. Update the decisions doc with the comment URLs.

## Phase 7: Notify the user

Ping the user only if the verdict is `BLOCK` or there are disagreements. Otherwise leave the decisions doc + posted comments and report the path silently.

```
PR #<n> review: <verdict>
- Blockers: <count>
- Disagreements: <count>
- Decisions doc: <abs path>
- Comments posted: <count, or "deferred">
```

Print the absolute path to the decisions doc (Nex needs full paths for click-to-open).

## Guidelines

- The baseline is the shared truth; perspectives react to it rather than re-deriving, keeping the four passes additive instead of duplicative.
- Always spawn the four perspectives in one message. Sequential is the failure mode this skill exists to fix.
- Codex runtime suits large diffs or perspectives that need to run code (typecheck, repo-wide grep); Claude runtime is faster and cheaper for pure reading.
- If `gh pr diff` exceeds ~5k lines, warn the user and offer to chunk by file before fanning out; do not silently truncate.
- Do not invent Linear tickets. No ticket and no ACs in the PR body: the acceptance-criteria perspective files a `question` finding and stops.
- Reuse review-code's references for team conventions; do not duplicate them here.
