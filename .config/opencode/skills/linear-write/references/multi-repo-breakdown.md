# Multi-repo breakdown

Default behaviour whenever the research finds that the change needs PRs in more than one repo. No prompt is needed to trigger it. A change confined to one repo stays a single card.

## Shape

- **Parent card:** the feature or fix as a whole, written from the parent template below. It carries the decisions every sub-issue must agree on, the feature-level acceptance criteria and the delivery sequence. It has no implementation guidance, because that lives in the sub-issues.
- **One sub-issue per repo that needs a PR**, each written from the standard agent-ready template, with `parentId` set to the parent. A repo that only needs a package bump or a schema mirror refresh still gets its own card if that change needs its own PR and deploy (e.g. a gateway schema refresh). Title each one for the change it makes, not for the repo, and name the repo in its Summary.
- **Design sub-issue**, when the change adds or alters UI and there is no finalised design yet. It blocks every build card whose contract depends on a design decision, which is usually every UI card and the schema card too if the design can change a field's shape or length. In it, record the decisions the build cards are waiting on (copy, placement, limits, states) and suggest designers without assigning one.
- **Labels:** the parent keeps its type label (`Feature`, `Bug`). Sub-issues get the team's sub-issue label (`subtask` on RR) plus `Design` on the design card. Sub-issues use the parent's team, project, milestone and state.

## Sequencing

Order the sub-issues by what has to be live before the next one can merge safely. Typical chain: schema/migration, then shared entity or ORM package, then API, then gateway or schema mirrors, then frontends. Publish and deploy gates matter as much as merges. A column must be live in every prod region before any consumer bumps the package, and an API field must be deployed before a client queries it.

Cards that don't depend on each other run in parallel. For example, the Manage frontend and the guest gateway plus guest frontend can both start once the API is deployed.

## Blocking relations

- Set the relations with `save_issue`'s `blockedBy` (append-only) when you create each sub-issue. Link each card only to the cards directly before it, not to the whole chain before it.
- The relations must match the Delivery sequence section exactly. Then Linear's blocked indicator and the parent's sequence tell the same story.
- Afterwards, spot-check a mid-chain card and a card at the point where the tracks split with `get_issue` (`includeRelations: true`).

## Creation order

Linear only expands an issue code once the issue exists, so:

- Create the parent first. Leave its Delivery sequence as a placeholder.
- Create the sub-issues in delivery order. Then every blocker already exists when you pass `blockedBy`, and a card can cite earlier siblings by code.
- Patch the parent's Delivery sequence with the real codes. Also patch any sub-issue that refers to a later sibling (e.g. 'live before RR-407 publishes'). Use `save_issue` `patch` and pass `state` explicitly, or the issue drops to the team default status.

## Cross-references

Always refer to a sibling or the parent by its bare code (`RR-407`), never by quoting its title. Linear expands the code into a chip that shows the full title, so a quoted title only duplicates it and goes stale if the title changes.

## Parent template

````markdown
## Summary

[One sentence: what the feature does for whom, and why]

## Background

- [Evidence and decisions, each with a platform citation: the request, prior incidents, who approved which option]

## Decisions pinned for all sub-issues

- [Field names at each layer, types, limits, null/blank semantics, where it is shown and where it is never shown, feature flag or not]

## Acceptance criteria

- [ ] [Feature-level, user-observable criteria; per-repo criteria live in the sub-issues]

## Scope

### In scope

- [Surfaces and repos covered by the sub-issues]

### Out of scope

- [Adjacent options not taken, related entities excluded, flows that don't render this]

## Delivery sequence

Each step is linked with a blocking relation, so a card cannot start until the ones before it are done.

- **Step 1:** RR-405. [Why it goes first, e.g. it can change the field length the schema uses.]
- **Step 2:** RR-406. [The gate that releases the next step, e.g. merge it and wait until it is live in every prod region.]
- **Step 3:** RR-407.
- **Step 4:** RR-408, [deploy gate, e.g. deployed to every region].
- **Step 5, two tracks in parallel:**
  - Guest track: RR-409, then RR-411.
  - Manage track: RR-410, which can run at the same time as the guest track.

## Rollout

- [Optional: who migrates existing workarounds or venues once it is live]

## Risk tier

[Low / Medium / High]: [justification across the whole change, including why deploy order matters]

## Due diligence

Run the [change due diligence checklist](https://app.notion.com/p/meandu/Ctrl-alt-delight-Change-Due-Diligence-Checklist-3803c6719946810f8b7edcb94b875130) on each sub-issue. Gates for the whole feature:

- [ ] [How it is used today, blast radius, two-step schema staging, teams to tell before a checkout/cart merge]

## Related

- [Bare issue codes with a short parenthetical, PRs]
````

Delivery sequence rules:

- Use one bullet per step with a bold `**Step N:**` label. Don't use a numbered list, because Linear drops items from numbered lists.
- Bare codes only. Linear expands them with the title, so don't repeat the title or the repo.
- After a code, add only what the code can't say: why this step goes first, or the merge, publish or deploy gate that releases the next step.
- Group parallel work under one step, labelled with how many tracks run in parallel and a short name for each track. Within a track, write sequential cards as `A, then B`.
