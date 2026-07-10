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

## Keeping the stack in sync

Creation is only half the job. Once the stack exists, two events force a local rebase. In both cases the branches move locally and must then be force-pushed with `--force-with-lease` (never bare `--force`).

### `main` moved under the whole stack

Rebase every branch in the stack in one pass. Check out the **top** branch and rebase onto `main` with `--update-refs`:

```bash
git checkout <top-branch>
git rebase main --update-refs
```

Git recognises the intermediate refs and updates them all — `pr-2` onto the new `main`, `pr-3` onto the new `pr-2`, and so on — so you don't rebase each branch by hand. Then push each updated branch:

```bash
git push --force-with-lease origin pr-1 pr-2 pr-3   # every branch the rebase moved
```

`--update-refs` moves the local refs but does not push them; each branch still needs its own force-push. (You can set `rebase.updateRefs = true` in git config to make `--update-refs` the default.)

### A lower PR merged

When `pr-1` merges, GitHub auto-retargets `pr-2`'s **remote** base to `main`, but the local `pr-2` branch still contains `pr-1`'s now-merged commits on top of the old base. Reparent it onto `main`, dropping the merged commits, with `git rebase --onto`:

```bash
git rebase --onto main pr-1 pr-2
```

Read this as "take the commits after `pr-1` on `pr-2`, and replant them onto `main`." Then `git push --force-with-lease` `pr-2`, and repeat up the stack for any branch whose parent just merged. Only after this reparent-and-push should you `gh pr ready` `pr-2` (per the Draft state rules above).
