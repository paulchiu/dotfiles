---
name: review-code
description: "End-to-end PR review: create a worktree, run a principal-engineer branch review, run a hostile adversarial second pass, optionally apply a persona focus-lens, optionally delegate an outside-view round to a Codex/cxd Nex pane, archive a decision doc to ~/dev/sandbox, and only post inline comments / approve / request changes when the user explicitly ticks actions. Use on `/review-code`, 'review this PR', 'review the branch', 'branch review', 'reviewing branch changes', 'adversarial review', 'hostile review', 'review as <name>', 'persona-based review', or when given a PR number/URL."
---

# Code Review Skill

Unified review workflow. Triggered by a PR URL, number, or (no arg) the current branch's open PR.

1. Resolve PR, create worktree.
2. **Round 1**: principal-engineer branch review.
3. **Round 2**: hostile adversarial second pass (once).
4. **Round 2.5 (optional)**: persona focus-lens re-rank.
5. **Round 3 (optional)**: Codex outside view via Nex `cxd` pane.
6. Write decision doc to `~/dev/sandbox/`.
7. Offer action checklist inline. Only post to GitHub when user explicitly ticks actions in the current turn.

## Inputs

- `42` → current repo, PR #42
- `https://github.com/<org>/<repo>/pull/42`
- (no arg) → current branch's open PR via `gh pr view`

Parse the user's prompt for optional flags:

- **Persona**: phrases like "review as <name>", "persona-based review by <name>", "hostile <name> review" → trigger Round 2.5 with that persona.
- **Skip rounds**: phrases like "skip adversarial", "branch-review only" → run round 1 only.

Resolve PR data at the start:

```bash
PR_DATA=$(gh pr view "$PR" --json number,url,headRefName,headRefOid,baseRefName,body,title,files)
```

If `gh pr view` fails (no PR for current branch, wrong repo), tell the user and stop. Don't guess.

## Step 1: Worktree

Create `~/dev/<repo>-pr-<num>` via `git worktree add`. Check out the PR's head ref into it. All subsequent reading and tool runs happen against this worktree.

```bash
REPO=$(echo "$PR_DATA" | jq -r '.url' | awk -F/ '{print $(NF-2)}')
HEAD_REF=$(echo "$PR_DATA" | jq -r '.headRefName')
BASE_REF=$(echo "$PR_DATA" | jq -r '.baseRefName')
PR_NUM=$(echo "$PR_DATA" | jq -r '.number')
HEAD_SHA=$(echo "$PR_DATA" | jq -r '.headRefOid')
WORKTREE=~/dev/${REPO}-pr-${PR_NUM}

git fetch origin "$HEAD_REF" "$BASE_REF"
git worktree add "$WORKTREE" "origin/$HEAD_REF"
```

No auto-cleanup; the user runs their own cleanup scripts. If the worktree path already exists, reuse it (`git worktree add` will refuse; switch into the existing path instead).

`cd "$WORKTREE"` before running diff / log / lint commands. The base ref for diffs is `origin/$BASE_REF`.

## Step 2: Round 1 (principal-engineer branch review)

Load review guidance, in this order:

1. `references/team-pr-references.md`
2. `references/pull-request-review-guidelines.md`
3. `references/other-team-pr-preferences.md`
4. If the repo is `manage-frontend` or the diff uses `@mr-yum/frontend-ui` → also `references/manage-frontend.md`.
5. `references/review-lenses.md`
6. `references/severity-and-ids.md`

In the worktree:

```bash
git diff origin/${BASE_REF}...HEAD
git log origin/${BASE_REF}..HEAD --oneline
git diff --name-only origin/${BASE_REF}...HEAD
```

Run targeted `rg` scans on changed files for feature-flag style, `any`, non-null assertions, logging patterns, etc. (batch these in parallel, not serially). Run lint/type checks for touched paths when available.

For wide diffs spanning several modules, fan the context work out: parallel Explore subagents check call sites and local conventions for each changed area while the main thread reads the diff. Carry forward their conclusions, not file dumps.

Apply the GPT-5.3 reasoning loop from `severity-and-ids.md` per finding. Collect findings with stable `REV-N` IDs and severities.

Build a risk map: mark security, payment, migration, infra, and user-visible behavior as high attention. Validate that tests cover behavioral changes; missing tests need explicit justification.

## Step 3: Round 2 (adversarial pass)

Treat round-1 findings as a draft to attack, not a finished list. Run this round as a fork, not a self-pass: attacking your own findings from inside the context that produced them inherits round 1's blind spots, and a cold reader does not. Spawn a subagent given only the artifacts (the worktree path, the diff refs, and the bare REV-N list: statement, file:line, severity, no round-1 reasoning) plus `references/review-lenses.md`, framed to refute. It applies each lens (bugs, regressions, missing edge cases, security, data integrity, test quality, build/CI supply chain) to:

- Add findings round 1 missed.
- Contest weak round-1 findings: is the impact realistic? Is there a clear rule? Recommend drop or downgrade if not.

Merge its output back; you keep final judgment on severity via the false-positive gate in `severity-and-ids.md`.

**Opportunistic AC trace.** If acceptance criteria are findable (PR body section `## Acceptance criteria` / `## ACs` / `## Requirements`; linked Linear ticket via `mcp__claude_ai_Linear__get_issue`; checkbox lists `- [ ]` / `- [x]`), trace each one against the diff and note only the ones **not met**. If no ACs are findable, skip the AC section entirely. Don't stop, don't ask.

Round 2 runs exactly once. Don't loop.

## Step 4: Round 2.5 (optional persona focus-lens)

Only if the user named a persona in the prompt.

Load `references/persona-lens.md` and apply:

1. Mine the persona's recent review history (delegate to a subagent if it'll take more than a couple of `gh` calls).
2. Extract focus areas, severity calibration, known exceptions, approve-style.
3. Re-rank findings; add ones the persona would have caught; drop ones they'd let slide.
4. Build the focus-area table (`| Finding | Pre-persona | Post-persona | Why |`) for the decision doc.

The persona is **lens, not voice**. Posted comments are always drafted in the user's voice using the wrapper in `references/posting.md`. See `persona-lens.md` for the full rule, push-back behavior, and self-check.

## Step 5: Round 3 (Codex outside view via Nex)

**Ask before writing the decision doc, unless a skip condition below applies.** Round 3 is the most reliable round at catching findings the self-passes miss (on PR #3708, cxd surfaced two AC violations and a boundary leak that rounds 1, 2, and 2.5 all missed). Skipping silently is the bug.

Ask the user once, before drafting the decision doc:

> "Send to a `cxd` Nex pane for an outside-view review? (round 3)"

Skip the ask only when:

- The user opted out explicitly in the original prompt ("skip round 3", "no cxd", "branch-review only", "rounds 1-2 only").
- The user opted in explicitly in the original prompt ("include cxd outside view", "do all three rounds", "full review with codex"): proceed without asking.
- Auto-mode is active AND the user opted out in this session or a recent one; otherwise even in auto-mode, ask.

If yes, use the `nex` skill to spawn a pane running `cxd`, hand it:

- The in-progress decision doc draft.
- The diff and worktree path.
- A short prompt: "Adversarially review _this review_. What did I miss? Which findings would you drop or downgrade?"

cxd's response often scrolls past the visible pane viewport. Ask cxd to write its full response (REV-N re-rank + missed findings) to a file like `/tmp/cxd-<pr-num>-review.md`, then Read that file. Don't try to reconstruct from `pane capture` alone.

Pull the response back in. Resolve disagreements:

- Codex flags a new issue not yet captured → verify against the diff first (don't take the claim at face value), then add as the next `REV-N`.
- Codex contests one of mine → re-evaluate against the false-positive gate in `severity-and-ids.md`; keep, downgrade, or drop.
- **Consensus** = no new findings added and none contested after this round.

If skipped (user opted out), round 2 (and 2.5 if run) output is final. Note "Round 3 skipped per user preference" in the decision doc.

## Step 6: Write decision doc

Before writing, re-verify every `blocking` finding against the worktree code (open the surrounding file, not just the diff hunk). Plausible-but-wrong findings are the main failure mode of model reviews; a dropped false blocking beats a defended one.

Default location: `~/dev/sandbox/`. Filename: `yyyy-mm-dd PR <num> <short title>.md` (preserve acronym casing; run `date +%Y-%m-%d` if today's date isn't in context).

After writing, **print the absolute path** so the nex terminal renders the click-to-open preview.

Template:

```markdown
# Code Review, PR #<num>: <title>

- URL: <pr url>
- Head: <short sha>
- Base: <branch>
- Worktree: <abs path>
- Reviewed: <YYYY-MM-DD>

## Verdict: <Approve | Request Changes | Needs Discussion>

<one-sentence justification>

## Risk Assessment: <Low | Medium | High>

<one-sentence justification>

## Possible actions

Tick the actions you want to take. The skill will execute the ticked ones on request.

- [ ] Post REV-1 inline (`path/to/file.ts:42`, blocking)
- [ ] Post REV-2 inline (`path/to/other.ts:88`, suggestion)
- [ ] Post REV-3 inline (`path/to/file.test.ts:120`, nitpick)
- [ ] Approve the PR (`gh pr review --approve`)
- [ ] Request changes (`gh pr review --request-changes`)
- [ ] Leave a top-level summary comment instead of inline
- [ ] Ask the author the open questions below
- [ ] No action; archive only

## Persona lens: <name> (omit section if no persona was used)

Focus areas: ...
Severity calibration: ...
Known exceptions: ...

| Finding | Pre-persona | Post-persona | Why |
| ------- | ----------- | ------------ | --- |
| REV-1   | suggestion  | blocking     | ... |

## ACs not met (omit section if no ACs found or all met)

- **AC2**: <text>. Where it should live: ...

## Findings

### `REV-1` blocking, `path/to/file.ts:42`

<plain issue statement>

Why this matters: <1-3 sentences>.

Recommended change:
\`\`\`ts
// minimal fix
\`\`\`

### `REV-2` suggestion, `path/to/other.ts:88`

...

## Open questions

- <thing the diff didn't make clear; ask the author>

## Notes

- <design choice you'd flag in a 1:1, related cleanup, etc.>
```

**Ordering** (in both `Possible actions` and `Findings`): `blocking` → `suggestion` → `question` → `nitpick`; within a severity, by file in diff order then ascending line.

## Step 7: Offer the action checklist inline

After writing the file, surface the same Possible-actions list in chat so the user can tick without opening the file. Single question:

> "Verdict: `<verdict>`. Risk: `<risk>`. <N> blocking, <M> suggestions, <K> questions, <L> nitpicks. Decision doc at `<absolute path>`. Which actions should I take?"
>
> - [ ] Post REV-1 inline
> - [ ] Post REV-2 inline
> - ...
> - [ ] Approve the PR
> - [ ] Request changes
> - [ ] No action

The user replies with the items to execute (or "all", "blocking only", "approve and post all", etc.).

**Never post or approve / request-changes without explicit user instruction in this turn.** A prior session's approval doesn't carry over.

## Posting, approving, requesting changes

See `references/posting.md` for the full `gh api` recipe, the `<details>` comment wrapper, file-level comment fallback, and the ultra-terse review-body style.

Quick summary of the wrapper (full rules in `posting.md`):

- `LLM note: <short>` first line.
- Plain opening paragraph after `<summary>` (no severity label).
- `(ref: REV-N)` as the last line outside `</details>`.

## Judgment notes

These encode what a strong reviewer does by default. Follow them regardless of which model is running the skill:

- Spend lens time where bugs actually live: state mutation, boundaries (serialisation, API contracts, null/undefined edges), ordering and time, and the interaction between changed and unchanged code. Read the call sites the diff did not touch; a correct-looking hunk with a stale caller is still a bug.
- Zero blocking findings after a real search is a valid outcome. Do not manufacture severity to look thorough; thoroughness is measured by verified findings, not finding count, and the false-positive gate outranks completeness.
- Delegate breadth (call-site checks, convention scans, persona history mining) to subagents; the main thread holds the diff and the judgment.
- Reviewers you spawn get artifacts only (diff, worktree path, bare findings list), never your reasoning, and are asked to refute rather than confirm. That applies to the round-2 fork and the cxd hand-off alike.
- Batch independent work in parallel: reference loads, `rg` scans, `gh` metadata calls.

## Notes

- Hostile-by-default reasoning, neutral-professional tone in posted comments. Don't ship sneering comments to GitHub.
- Don't waive findings because legacy code does the same thing; note the legacy issue separately if it matters.
- Australian spelling. No em dashes.
- The decision doc is the source of truth. If the user later asks "what did we find on PR 42?", read the archived file rather than re-running the review.
- This skill consolidates the previous `adversarial-review` and `reviewing-branch-changes` skills; their triggers route here via the description above.
