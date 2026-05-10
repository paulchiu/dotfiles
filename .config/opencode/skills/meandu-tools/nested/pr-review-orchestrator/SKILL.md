---
name: pr-review-orchestrator
description: "Multi-perspective PR review orchestrator. Runs the reviewing-branch-changes skill as a baseline, then fans out 4 specialised perspectives (security, performance, acceptance-criteria, style) in parallel via codex or Claude subagents (user picks at invocation), aggregates findings into a single verdict, and posts inline comments via gh."
---

# PR Review Orchestrator

Run a multi-perspective review of a GitHub PR by combining the `reviewing-branch-changes` baseline with four specialist perspectives, plus an optional CodeRabbit pass. Aggregate, deduplicate, and post inline comments. Only escalate to the user when reviewers disagree or a blocker is found.

## Input

The user provides a PR identifier:

- `123` (current repo)
- `mr-yum/<repo>#123`
- A full GitHub PR URL

If no PR is given, default to the current branch's PR (`gh pr view --json number,url`).

## Phase 0: Pick the runtime

Before doing anything else, ask the user:

> Run perspectives via **codex** (parallel `codex:codex-rescue` agents) or **Claude** (parallel `general-purpose` agents)?

Also confirm:

- **Run CodeRabbit in parallel?** (default: yes if the repo is wired for it; skip on auth error)
- **Auto-post comments after aggregation, or stop at the decisions doc for review?** (default: stop at decisions doc)

Do not proceed past Phase 1 until the user answers. Capture answers as `RUNTIME`, `CODERABBIT`, `AUTO_POST`.

## Phase 1: Gather PR context

Run in parallel:

```
gh pr view <pr> --json number,url,title,body,headRefOid,headRefName,baseRefName,headRepository,baseRepository,files,additions,deletions
gh pr diff <pr>
```

From the PR body and branch name, extract any Linear ticket ID (e.g. `CAD-1709`, `CUSM-642`). If found, fetch the ticket via `mcp__claude_ai_Linear__get_issue` for acceptance criteria and scope context.

Capture and reuse throughout the session:

- `PR_NUMBER`, `PR_URL`, `HEAD_SHA`, `HEAD_BRANCH`, `BASE_BRANCH`, `OWNER/REPO`
- Changed files (path + ±lines)
- Linear ticket text (if any) — especially acceptance criteria
- A local checkout of the branch is **not** required; reviewers can read the diff via `gh pr diff` and individual files via `gh api repos/<owner>/<repo>/contents/<path>?ref=<sha>`. If the user wants a local working tree, ask before running `gh pr checkout`.

## Phase 2: Baseline review

Run the `reviewing-branch-changes` skill as the **shared baseline** all perspectives build on. This produces the canonical checklist of findings with stable IDs, severity, and file:line targets.

Two ways to invoke, depending on whether the PR is checked out locally:

- **Local checkout available:** invoke `reviewing-branch-changes` directly against `<base>...HEAD`.
- **PR-only mode (no checkout):** spawn one `general-purpose` Agent with the `reviewing-branch-changes` skill loaded, brief it with the PR metadata, the full `gh pr diff` output, the linked Linear ticket, and instructions to follow that skill's contract verbatim. The output must include the checklist with stable IDs.

Save the baseline output to:

```
outputs/pr-reviews/<owner>-<repo>-<pr>/<yyyy-mm-dd>/00-baseline.md
```

This file is the **shared input** for every perspective in Phase 3. Each perspective will reference baseline finding IDs (e.g. `BASE-DT-1`) when they agree, extend, or disagree.

## Phase 3: Fan out four perspectives in parallel

Spawn the four perspective agents in a single message so they run concurrently. The agent runtime is determined by `RUNTIME` from Phase 0.

### Codex runtime

```
Agent({
  subagent_type: "codex:codex-rescue",
  run_in_background: true,
  description: "<perspective> review of PR #<n>",
  prompt: "<perspective brief — see below>"
})
```

### Claude runtime

```
Agent({
  subagent_type: "general-purpose",
  run_in_background: true,
  description: "<perspective> review of PR #<n>",
  prompt: "<perspective brief — see below>"
})
```

### Shared brief (every perspective gets this)

```
You are the <PERSPECTIVE> reviewer for <OWNER/REPO>#<PR_NUMBER>.

PR: <PR_URL>
Branch: <HEAD_BRANCH> @ <HEAD_SHA>
Base: <BASE_BRANCH>
Linear ticket (if any): <ID> — acceptance criteria pasted below.

You DO NOT start from scratch. The baseline review is at:
  outputs/pr-reviews/<key>/<date>/00-baseline.md

Read the baseline first. For each baseline finding that falls inside your perspective:
- Confirm (cite finding ID, agree)
- Extend (add detail or evidence the baseline missed)
- Downgrade/Disagree (explain why the baseline is wrong from this perspective)

Then add NEW findings the baseline missed that are specific to your perspective.

Use the reviewing-branch-changes finding format for your additions:
- Stable ID prefixed with your perspective (SEC-1, PERF-1, AC-1, STYLE-1)
- file:line target
- severity (blocking | suggestion | question | nitpick)
- 1-3 sentence rationale
- recommended fix (concrete, not abstract)

Output format:
## Perspective: <PERSPECTIVE>
### Verdict: BLOCK | NITPICKS_ONLY | CLEAN
### Baseline reactions
- BASE-XX-1: confirm | extend | disagree — <reason>
### New findings
- <ID> file:line — severity — summary; fix: …
### Notes
- Anything you investigated but ruled out, in 1 line each.

Save your output to:
  outputs/pr-reviews/<key>/<date>/0<n>-<perspective>.md

Diff is at <gh pr diff command output> and individual files via:
  gh api repos/<owner>/<repo>/contents/<path>?ref=<HEAD_SHA>
```

### Per-perspective addenda

Append exactly one of these to the shared brief per agent:

**security-reviewer (`01-security`)**
> Focus: authn/authz, input validation, injection (SQL/HTML/shell), secrets handling, PII exposure, payment safety, SSRF, deserialisation, dependency CVEs introduced by package changes, CSRF, race conditions in security-critical paths, log injection. Treat payment/PII/auth changes as high-risk and require very high confidence. Ignore non-security issues unless they enable a security one.

**performance-reviewer (`02-performance`)**
> Focus: N+1 queries, missing indexes / migration safety, unnecessary `Promise.all` over serial work, blocking CPU work in request handlers, large payloads, memoisation gaps, render thrash on the FE, list virtualisation, bundle-size hits from new deps, Tailwind class explosion, expensive regexes. Quote concrete evidence (line + caller). Ignore non-perf issues.

**acceptance-criteria-reviewer (`03-acceptance-criteria`)**
> Focus: trace each AC from the linked Linear ticket against the diff. Map AC → file:line that fulfils it, or flag as MISSING. Also flag scope drift (changes not justified by an AC) and behaviour changes that contradict ACs. If no Linear ticket exists, derive ACs from the PR description and flag the absence of a ticket as a `question`. Be explicit: "AC1 ✅ at <file:line>", "AC3 ❌ — no implementation found".

**style-reviewer (`04-style`)**
> Focus: team conventions in `references/team-pr-references.md` and `references/other-team-pr-preferences.md` from the reviewing-branch-changes skill — naming, logging strings, feature flag style, Promise handling, money math, DAO patterns, FE conventions, Tailwind tokens, TypeScript `any`/non-null assertions, comment hygiene per Paul's CLAUDE.md (no em dashes, JSDoc blocks). Ignore correctness/security/perf issues unless they violate a written convention.

### CodeRabbit (optional, parallel)

If `CODERABBIT == yes` and the repo supports it, also run:

```
coderabbit review --plain --type committed --base <BASE_BRANCH>
```

backgrounded so it overlaps the four perspectives. On auth or network failure, surface and continue without it.

## Phase 4: Aggregate

Once all perspective files exist (and CodeRabbit if used), build the aggregate:

```
outputs/pr-reviews/<key>/<date>/aggregate.md
```

Aggregation rules:

1. **Deduplicate by `file:line + intent`.** When two perspectives flag the same line for the same reason, keep one finding and note `also flagged by: <perspectives>`. Different concerns at the same line stay separate.
2. **Resolve conflicts.** If perspectives disagree on severity, take the highest. If they disagree on whether a finding is valid, surface it under "Disagreements" — do **not** silently drop.
3. **Map every finding to a global ID** (`PR<n>-AGG-1` …) and keep a back-reference to the original perspective IDs.
4. **Compute the overall verdict** from severity:
   - `BLOCK` if any aggregated finding is `blocking`
   - `NITPICKS_ONLY` if only `nitpick` and `question` findings remain
   - Otherwise `CLEAN`
5. **Group output by severity**, then file diff order.

The aggregate must include:

- Verdict (BLOCK | NITPICKS_ONLY | CLEAN)
- Disagreements (if any) — these are the user-ping triggers
- Findings table grouped by severity
- For each finding: global ID, file:line, severity, summary, fix sketch, source perspectives, baseline ID if applicable
- A short reasoning trace per perspective ("security: focused on the new webhook handler; ruled out CSRF because …") so the user can audit why each agent landed where it did

## Phase 5: Decisions doc

Write the canonical decisions doc to:

```
outputs/pr-reviews/<key>/<date>/decisions.md
```

Structure:

```md
# PR Review Decisions — <OWNER/REPO>#<PR>

- PR: <PR_URL>
- Reviewed: <date> @ <HEAD_SHA>
- Runtime: codex | claude
- CodeRabbit: yes/no
- Verdict: <verdict>

## Per-reviewer reasoning
### security
<1-paragraph: what they looked at, what they ruled out, what they flagged>
### performance
…
### acceptance-criteria
…
### style
…
### coderabbit (if run)
<P0/P1/P2 summary>

## Disagreements
<list, or "None">

## Final findings
<from aggregate.md>

## Action
- [ ] Comments posted to GitHub: <yes/no, list URLs>
- [ ] User ping required: <yes/no — only yes if BLOCK or disagreements>
```

## Phase 6: Post inline comments (only if `AUTO_POST == yes`)

Group findings by severity, then post via `gh api` per the `reviewing-branch-changes` skill's "Posting With gh" section. One inline comment per finding, anchored to the changed line in the diff hunk; file-level comment when no anchor exists.

Use the global aggregate ID in each comment so back-tracing is possible. Skip `nitpick` findings unless the user explicitly asks to post them.

After posting, update the decisions doc with the comment URLs.

## Phase 7: Notify the user

**Only ping the user if** the verdict is `BLOCK` **or** there are disagreements between reviewers. Otherwise, leave the decisions doc + posted comments and report the path silently.

Notification format:

```
PR #<n> review: <verdict>
- Blockers: <count>
- Disagreements: <count>
- Decisions doc: <abs path>
- Comments posted: <count, or "deferred">
```

Print the absolute path to the decisions doc per Paul's CLAUDE.md (Nex needs full paths for click-to-open).

## Guidelines

- The baseline review is the shared truth — perspectives react to it rather than re-deriving findings, which keeps the four passes additive instead of duplicative.
- Always run the four perspectives in parallel (single message, multiple `Agent` tool calls). Sequential is the failure mode this skill exists to fix.
- Codex runtime is preferred when the diff is large or when perspectives need to run code (typecheck, grep across the repo). Claude runtime is faster and cheaper for pure reading work.
- Keep the decisions doc as the durable artefact; the GitHub comments are the user-visible surface, the doc is the audit trail.
- If `gh pr diff` is enormous (>5k lines), warn the user and offer to chunk by file before fanning out — do not silently truncate.
- Do not invent Linear tickets. If no ticket is linked and the PR body has no ACs, the acceptance-criteria perspective files a `question` finding and stops.
- Reuse `reviewing-branch-changes` references for team conventions; do not duplicate them in this skill.
