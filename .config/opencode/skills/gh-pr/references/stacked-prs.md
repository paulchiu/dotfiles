# Stacked PRs

For PRs in a stacked series (each PR's base is another PR's branch, not `main`), two adjustments apply.

## Body prepend

Add this admonition above the template body:

```
> [!NOTE]
> **PR N of M** in the <short stack name> stack. Stacked on #<parent-number> (or `main` for PR 1).
>
> Review bottom-up (PR 1 → PR M):
> 1. #NNNN — <short title>
> 2. #NNNN — <short title>
> ...
```

Format rules:

- Use the `> [!NOTE]` GitHub admonition. Do not use a `## Stacked PRs` heading or a `---` separator before the body.
- Keep one blank `>` line between the "Stacked on" line and "Review bottom-up".
- Every list line is prefixed with `> ` (the list lives inside the blockquote).
- Each item reads `#<number> — <short title>`. The current PR is `**#<number> — <short title> ← this PR**`.
- "Stacked on" points to the immediate parent PR, not the eventual base. PR 1 uses `` `main` ``.

## Base branch

Pass `--base <parent-branch>` on `gh pr create` for every PR except PR 1. PR 1 targets `main`; each subsequent PR targets its predecessor's branch.

## Numbering

PR numbers are assigned at `gh pr create` time. Create PRs 1 → M first (bodies can omit the numbered list initially), then edit each body with the final numbers once the whole stack exists.

## Draft state

Create every PR in the stack as a draft (`gh pr create --draft`, per Step 3). Then:

- **Ready only the bottom PR** (PR 1, base `main`) when it is ready for review.
- **Keep PRs 2..M as drafts** until each one's base (the PR below it) merges. An upper PR cannot merge or be meaningfully reviewed against `main` while its base is an unmerged branch, so readying it invites premature review and misrepresents it as mergeable.
- When PR N merges, GitHub auto-retargets PR N+1's base to `main`. Only then `gh pr ready` PR N+1.

A caller that marks every stacked PR ready at once (e.g. a blanket `gh pr ready` loop after CI goes green) is a defect — ready is per-PR and gated on the base having merged.
