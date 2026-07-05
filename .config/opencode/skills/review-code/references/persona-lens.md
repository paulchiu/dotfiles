# Persona lens

Optional refinement step. A persona is a **review-focus lens, not a voice**. Use a persona to decide what to upweight, downweight, or surface; never to mimic their voice in posted comments.

Triggers: user says "review as X", "persona-based review by X", "hostile X review", or names a real reviewer alongside the PR input.

## The rule

- Use the persona to decide **what areas to surface**, **what to upweight or downweight**, and **what they'd let slide**.
- Do **not** mimic their voice, register, formatting habits, emoji use, lowercase-first style, or signature phrasing in the actual posted comments.
- Posted comments always use the user's voice + the wrapper in `posting.md` (`LLM note:` prefix, `(ref: REV-N)` suffix).

## Why

A persona's review history is signal about their **priorities and blind spots**: which areas they zoom in on, which they ignore, what severity calibration they tend toward. That signal is what gets layered into the consensus.

Their **voice** is not signal worth propagating:

1. Posting in someone else's voice is misleading; even draft comments framed as "what X would say" leak into actual posts.
2. The user's own voice is already specified (no em dashes; terse; lead with the answer). Mixing a third voice in confuses the output.
3. Format consistency matters more than register. The `LLM note:` + `(ref: REV-N)` format is what makes comments scannable across PRs.
4. The interesting work is the **focus reshuffle**, not the costume. If consensus already mirrors what the persona would prioritise, the lens added value. If not, the lens reshuffled the severity table; that's the deliverable.

## How to apply

### Step A: Mine the persona's review history

Use a subagent if it'll take more than a couple of `gh` calls. Look at their recent inline comments on PRs in the same org. Extract:

- **Focus areas**: what topics they comment on most (a11y, types, perf, tests, design-system fidelity, security, etc.)
- **Severity calibration**: do they block, suggest, question, nit? What's their default?
- **Known exceptions**: things they explicitly do **not** flag (e.g. if the persona introduced a pattern themselves in a recent PR, don't flag it on a persona-style review).
- **Approve style**: do they approve-with-comments, dismiss own reviews, require changes?

### Step B: Re-rank the existing findings

For each finding from round 2, ask:

- Would this persona block, suggest, question, nit, or ignore?
- Would they have surfaced a finding I missed under their focus areas?
- Would they let a finding I raised slide?

Build a focus-area table:

```markdown
| Finding | Pre-persona | Post-persona | Why |
| ------- | ----------- | ------------ | --- |
| REV-1   | suggestion  | blocking     | X consistently blocks design-system divergence (link to past PR) |
| REV-7   | blocking    | (dropped)    | X introduced this pattern themselves in PR #2371 |
```

Each row has a one-line "why" rooted in the persona's history. Append the table to the decision doc under `## Persona lens: <name>`.

### Step C: Update the consensus

Apply the re-rank. Add findings the persona would have caught. Drop findings they'd let slide. Renumber `REV-N` only if a finding was dropped from the middle (otherwise leave gaps; IDs are stable).

### Step D: Draft comments in the user's voice

**Do not write the comments in the persona's voice.** If drafting "nice, glad to see…" or starting with an emoji or going lowercase-first, stop. Re-draft using the wrapper in `posting.md`.

## Push-back rule

If the user says "comment as X" or "write this in X's voice", confirm once:

> "Personas usually mean focus areas, not voice. Do you want this drafted in your voice with X's focus lens, or actually mimicking X?"

Don't assume impersonation is the intent.

## When the persona is the user (Paul)

Not a persona pass at all. Default behavior: standard voice + format from `posting.md`.

## Self-check before writing the decision doc

- Drafted in the user's voice, not the persona's?
- Every actionable comment has `LLM note:` and `(ref: REV-N)`?
- Severity in the checklist, not as a label inside the `<details>` body?
- Did the persona reshuffle the severity table, or did I just rewrite findings in their voice? If the latter, the persona pass added no value: discard and redo.
- No em dashes anywhere.

## Provenance

The lens-not-voice rule originated from the chloe cad-1805 review session (manage-frontend PR #2338).
