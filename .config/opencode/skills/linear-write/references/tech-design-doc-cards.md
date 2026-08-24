# Technical Design Doc Cards

A card whose deliverable is a technical design doc, not code. Read this when the ask is 'write the tech design doc for X', or when a feature card turns out to be too ambiguous to build and the honest next step is a design doc rather than a spike.

## The shape

The deliverable is a document, so the card has two jobs and must keep them apart:

- `## Background` is pure context. Reference material the author reads before drafting. It states what is known, what is assumed, and what is contested. It never instructs.
- `## Instructions: produce the baseline draft` is a brief for whoever (or whatever) writes the doc. It instructs and nothing else.

Paul asks for this split explicitly. Mixing them produces a card that reads like a half-written design doc, which is the failure mode to avoid.

## Define 'baseline' in the card

The word is load-bearing and every reader guesses differently. Spell it out, roughly:

> A first complete draft: every section present and written, evidenced claims filled in with citations, unevidenced claims explicitly marked as assumptions with a proposed way to verify each, and the decisions that need a human deliberately left open with a recommendation and a named owner. Not a skeleton of headings, and not a signed-off design.

## Do not write an implementation spec

This is the most common overreach. The doc does its own code research; the card only points at where to look. Research the code anyway, then use the findings for exactly two things:

- A `### Codebases to explore` list: repo name, `([GitHub](...))`, and one line on what question that repo answers. Name directories and files worth opening, not a change plan.
- A `### What the code already says` list of red flags, each framed as a question the doc must answer rather than an answer the doc should copy. Prefix with a line saying this is a head start, not citable without re-verification.

Everything else the research turned up stays out. If a finding demolishes a premise in the PRD, say so in one bullet with its citation and let the doc do the work.

## Outline: recommend, don't mandate

Point at the me&u Technical Design Doc template ([Notion](https://app.notion.com/p/31a1bb5d00ae41f19b449f87e02575df)) and say to keep its H1 anchors in order with house casing so the doc reads like its siblings. Then give permission to deviate: add sections between them freely, and where the work genuinely does not fit a heading, drop or rename it with a one-line reason rather than leaving prompt text in place.

The house H1 spine, in order:

- `# Overview`, 2 to 6 sentences, approach and cost on the first screen
- `# Background`, including a `### Terms used` glossary when the domain has jargon
- `# Objective (Goals & non-goals)`
- `# Requirements`, as `## REQ-01` onward in Given/When/Then, each with a `**Verification:**` clause
- `# Detailed Technical design`, the bulk, with `## Key decisions` as `### D1.` records
- `# UAT/Test Plans`
- `# Third-party\External considerations` (note the backslash, it is in the template)
- `# Rollout`, with `## Deployment` and `## Rollback`
- `# Warranty`
- `# Alternatives Considered`
- `# Open Questions`

Above `# Overview`, ask for a header-block callout carrying the position and the pointers to the PRD, the originating issue, this card, and any doc that contradicts the plan.

For models of what good looks like, search Notion for design docs authored by Paul, Kayleigh Slogrove, Jure, or Ben Thompson before inventing structure.

## Uncertainty discipline

The part existing documents usually get wrong, so make it explicit in the card:

- Three tiers, used consistently: verified in code (repo, commit, `file.ts:line`), verified with the third party (with the source), assumed.
- Every unverified claim gets a verification path: who does it, against what, and what result confirms or falsifies it. An assumption with no verification path is not finished.
- Label claims sourced from an unvalidated document inline, at the point of use, as **asserted, unverified**. Name the specific artefacts that are not evidence.
- Never let the doc state or imply a validation exercise happened when it did not.
- Where research is thin, say it is thin. 'The vendor's over-redemption behaviour is undocumented and untested' beats an invented error taxonomy.

## Open decisions stay open

If the card's own subject rests on an unresolved architectural decision, the doc recommends and a human signs off. Put the decision in `## Key decisions` as `D1`, carrying a recommendation, the named rejected sibling with why, and the sign-off it needs. Put 'deciding it' in Out of scope, with an instruction to stop and escalate rather than silently rescope if the recommendation goes the way that invalidates the card.

Watch for the matching contradiction: do not demand a concrete artefact whose precondition is that same open decision. Scope those sections to the *recommended* option and say plainly they are void if the decision goes the other way. Do not ask for speculative work covering both branches.

## Open questions get numbers

Number them `Q1` onward as bold prefixes inside bullets, never a markdown ordered list (Linear truncates numbered lists saved via MCP). Every question carries a named owner, a person or a team, not 'TBD'. Later questions may reference earlier ones by number.

Then close the loop: the acceptance criteria say each of `Q1` to `Qn` is either resolved in the doc with evidence, or carried into the doc's `# Open Questions` under its `Q` number with lettered options and a named owner. Tell the doc to keep the numbers so the two artefacts stay cross-referenceable.

## Where the doc lands

Design docs live in the Technical Design Docs database ([Notion](https://app.notion.com/p/70159cc11a874da6a6f2fc5eccd244fc?v=fc1f933f8ee1459a95e9899024d9cf81)), under Engineering Team. Instruct the author to:

- Create the page from the `[TEMPLATE]: Technical Design: <SERVICE/FEATURE NAME>` template.
- Name it `Technical Design: <feature>`.
- Set `Status` to `Draft`, `Owning Team` to the owning squad, `Authors` to whoever wrote it, and `Linear Project` to the project URL. Leave `Reviewed by` empty.
- Keep a markdown working copy at the sandbox root as `yyyy-mm-dd <Title>.md` and print its absolute path, so the draft is diffable outside Notion.

Put 'moving the doc past `Draft`' in Out of scope; review is a separate step.

## Risk tier

Low as a change, because the card produces a document and alters no production behaviour. Say that plainly, then note the leverage separately if the doc gates something committed or expensive. Do not inflate the tier to signal importance.

## When it supersedes an existing issue

Design-doc cards often absorb an older requirement issue. Before closing that issue as a duplicate, copy its substance into a collapsed section on the new card verbatim: the original solution steps, every acceptance criterion, and any references it carried. The acceptance criteria usually become the `# Requirements` REQ IDs, so losing them behind a closed ticket costs real work.

```markdown
+++ <CODE> content (closed as duplicate, YYYY-MM-DD)

[verbatim solution steps, ACs, carried references]

+++
```

Then set `duplicateOf` in its own `save_issue` call; Linear rejects `duplicateOf` and a duplicate `state` together, and flips the status itself.

## Before saving

Run the cold-read test from the main skill, and check the specific failure modes these cards attract:

- A claim in Background contradicted by another claim in Background.
- An acceptance criterion that mandates what the Instructions call optional, or vice versa.
- A code claim carried from a doc or a stale local checkout rather than verified against `origin/main`. Fetch and check the line numbers; permalinks pin to the SHA.
- An instruction to contact an external party directly when an internal relationship owner exists. Route vendor questions through the owner.
