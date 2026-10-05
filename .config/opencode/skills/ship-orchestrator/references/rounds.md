# Rounds

How to ship sub-issues that block each other. Sub-issues with no blockers between them all go in round 1 and this file doesn't apply.

## Build the graph

- Read every sub-issue with `get_issue` (`includeRelations: true`). Linear stores a relation on one side (one issue's blocked-by is the other's blocks), so collect edges from both directions across all sub-issues and dedupe. Include blockers outside the parent.
- A sub-issue with no repo (a design card, an external blocker) gets no tab, agent or In Progress change. It appears in the plan only as the gate it releases, and you watch its Linear status.
- Read the parent's `## Delivery sequence` if it has one (the `/linear-write` multi-repo format: `**Step N:**` bullets, parallel tracks, and the gate that releases each step). It says which gate releases each step, which relations alone don't.
- If the relations and the Delivery sequence disagree, follow the stricter of the two and point out the mismatch in the plan. Don't edit Linear to reconcile them.
- A cycle is a card error: stop and show Paul the cycle.

## Gates

Each edge gets one gate, the condition under which the blocked sub-issue may start. Take it from the Delivery sequence wording; with no wording, default to **merged**.

| Gate | Released when | How to check |
| --- | --- | --- |
| design | the design sub-issue is Done, or Paul says the decisions it records are final | Linear status, or ask Paul |
| merged | the blocker's PR is merged to main | `gh pr view <n> -R <owner/repo> --json state,mergedAt` |
| deployed | merged, and live in every production region the Delivery sequence names | `bk-buildkite` skill, or ask Paul which pipeline proves each region |
| external | a blocker outside the parent is Done | Linear status |

A dependency only on deploy order (the blocked repo can be built and reviewed against an agreed contract, but mustn't merge first) needn't be a start gate. When the parent's pinned decisions or the card spell out the contract, offer in the plan to start it early; default to keeping the gate. If Paul agrees, add to its ship prompt `don't merge before [blocker] is [gate]; the contract is [where it's pinned]`, and repeat that note in the tab's 👀 report, since Paul is the one who merges.

## Rounds

- Round 1 is every sub-issue with no unreleased gate. Round N is every sub-issue whose blockers are all in earlier rounds. Parallel tracks in the Delivery sequence fall out of this naturally.
- The plan shows one table per round: sub-issue, repo, tab label, personas and extras, and for rounds 2 and later the gate each one waits on.
- Paul's go on the plan approves every round. Create tabs, start agents and set In Progress only when a sub-issue's round starts, not ahead of time.

## Releasing the next round

- Gates usually clear only after Paul merges, so watch in the background: a slow until-loop (`sleep 300` inside it) over each pending gate's check, recorded in the run file. The Linear MCP can't run in a shell loop, so check design and external gates with the `linear` CLI: `linear issue view <ID> --json --no-comments | jq -r .state.name`.
- For a blocker PR this run didn't open, find it from the issue's attachments (`get_issue`) or `gh pr list -R <owner/repo> --search <branch> --state all`.
- When any sub-issue's PR merges (the gate loop sees blockers; check the rest whenever you wake), tell its agent so it removes its worktree, and label the tab ✅. Leave the tab open.
- Start each blocked sub-issue as soon as its own gates clear, even if the rest of its round is still waiting. Rounds are for planning; start times follow the gates.
- When you start one, tell Paul which gate cleared, and add context to its ship prompt: `[blocker] landed in [PR link] at [merge SHA]; build on main and use what it added rather than redefining it.`
- When a round's last PR goes 👀, remind Paul which sub-issues its merge or deploy will release, once, in the 👀 report. That's a fact Paul needs to plan, not a nudge to merge, and the no-Friday-merge rule still applies.

## Starting early on a stacked branch

Paul may want a blocked sub-issue built before its blocker merges. Offer it in the plan only for a `merged` gate on a blocker in the same repo, and only when the blocker's PR already exists. If Paul agrees, the ship prompt says: `use a worktree branched from [blocker branch] and open the PR against it, following ~/.claude/skills/gh-pr/references/stacked-prs.md; when [blocker PR] merges, rebase onto main and retarget the PR to main.` Watch the blocker PR: when it changes, tell the dependent agent to rebase; when it merges, tell the agent to rebase onto main and retarget.

## Mid-run changes

- If a blocker's review changes something a dependent relies on (a field name, a contract), send the dependent a parity prompt as in feedback-and-parity.md.
- If a running sub-issue turns out to need another one first, stop that agent at a clean point (`herdr agent prompt <name> "stop after committing what you have; don't push"`, then wait for idle), tell Paul, and propose the new edge. Don't add Linear relations yourself.
