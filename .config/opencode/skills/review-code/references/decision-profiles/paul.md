# Decision profile: Paul

How Paul ticks the `## Possible actions` checklist in a decision doc. Mined from 140 ticked decision docs dated 2026-09-15 to 2026-10-13 (sandbox root plus `archive/`). Per-doc extracts live in `~/dev/sandbox/.agents/skills/review-autopilot/local/profile-mined/`. Regenerate by re-mining a fresh 4-week window the same way; bump the window line above when you do.

A profile is a **decision lens, not a voice** (the same rule as `../persona-lens.md`). It decides which boxes to tick. It never drafts or rewords comment text.

## How to apply

Triggered by "decide as Paul" (or "apply Paul's decision profile") against a finished decision doc.

1. Read the whole decision doc, including any round notes. Also check the doc and its record for a standing withhold (`no_auto_approve`, "do not approve", "leaving to <team>").
2. Tick boxes in `## Possible actions` item by item using the rules below. Change only `[ ]` to `[x]`. Never reword, add or delete option lines, and never untick a box Paul already ticked.
3. Append a `## Profile decisions` section at the end of the doc:
   - One line for every option you ticked or deliberately left: `REV-N (or option label): ticked | left. <rule>. <one-line reason>`.
   - A `Review level:` line naming the choice and the rule behind it.
   - A `For Paul:` list of anything the profile says to leave for him (see "Leave for Paul"), or `none`.
   - A `Confidence:` line, high, medium or low, plus the reason when it's not high.
4. **Post nothing.** Ticking is the whole job: no GitHub comments, no approval, no thread resolves, no Linear or Slack. The hold on posting only lifts when Paul asks for his decisions to be actioned. Leave the herdr workspace label alone.
5. Report in at most four lines: review level, ticked count against offered count, the `For Paul` items, and confidence.

## Review level

- **Never tick Request changes.** He has ticked it 0 times in 140 docs, including about 20 with a Request Changes verdict. A code blocker goes up as an inline comment instead, and approval waits for the re-review.
- **Approve** (plain approve, with the findings as separate inline comments) when no code-correctness blocker is open and none of the withhold conditions below apply. This is the default: about 70% of docs were approved on the first pass, often with 5 to 15 suggestions and nits still open.
  - Low risk: approve, even with open suggestions.
  - Familiar repos (manage, manage-frontend, serve-frontend, crew) from Responsive Roadmap or close peers (Kayleigh, Shawn, Steph, Tal, Abhaya): approve with nits by default.
  - Test-only, e2e, docs, rename or comment-only changes: approve, even over a blocker that has no runtime risk.
  - A blocker that is only deploy or merge ordering doesn't count as open. That finding gets dropped (see Findings) and the approval stands.
  - Trusted authors: PRs by Benno007 or Jure (yflander) get the normal approve rules above. The another-team deferral below, Ordering and Payments in particular, doesn't apply to them: they are on Ordering and Payments themselves and Paul has high confidence in their work. Don't list it under `For Paul:` as a deferral.
- **Comment only, no approval**, when any of these hold:
  - A code-correctness or security blocker is open. Approval comes on the re-review once the fix is verified.
  - Medium or high risk on a money, payment, loyalty-redemption or data-deleting path.
  - Another team owns the area (Loyalty, Payments, Ordering and Payments, Core Ordering, Core Integrations, Hotel, PULSE, guest-gateway, loyalty-connector), unless the author is a trusted author (see above). Tick the matching "leaving to <team> to approve" option if the doc offers one. If it offers none, say so under Review level with the body Paul uses, `Leaving to <Team> reviewers to approve first.`, and still leave Approve unticked.
  - Many substantive asks on the first pass: about 10 or more non-nit comments, or open questions about behaviour or security.
  - On a re-review: the build is red or typecheck is broken.
  - An upstream PR this one depends on is still unmerged.
  - The PR has already merged: comment only, and tick the "acknowledge merged" option if offered.
  - The doc or record carries a standing withhold. That outranks everything here.
- **Defer to the owning team more readily than feels necessary.** Paul has overridden the profile toward deferral several times (serve-api#1662 and manage#5328 to Ordering and Payments, serve-frontend#3189 to Hotel, 2026-10-15/16), and the other way only for a trusted author (manage#5362, 2026-10-16). Ownership is not only the repo: read the PR's requested reviewer teams and its CODEOWNERS for the touched paths. When a team Paul is not in is requested or owns those paths, defer, even if he is also requested through a shared team (serve, manage) and even when a low-risk, familiar-repo or close-peer rule says approve. Name the team in the deferral. The trusted-authors exception above still applies. Only Responsive Roadmap, Serve, Manage and Crew work counts as his own. Every deferral is an override Paul may want, so also list it under `For Paul:` as one line he can answer from his phone: `Deferred to <Team>. Approve anyway?`
- **Approve with the hold in the body** only when the sole open item is a process gate Paul owns, such as a soak or a merge hold. Otherwise tick plain approve over "approve with the nits in the body".
- Never tick "No action", "Leave a top-level summary comment" (in place of inline comments), or "Dismiss the standing approval" unless the doc says Paul asked for it.

## Findings

Approximate post rates: nitpick 93%, suggestion 91%, blocking 80% (every code blocker), question 55%. Severity is not the filter. The kind of ask is.

**Tick (post)**:
- Every code-correctness and security blocker.
- Suggestions and nits, including style ones: comment hygiene (comments that restate code, long comments, ticket refs in comments), `as` casts, nested ternaries and deep conditionals, unnamed conditions, reuse of an existing helper or library, layering (logic belongs in a service, store or mapper), exhaustive switches, file length.
- Ignore any advice in the doc, from Codex or from a lens, to prune nits. He posts them anyway.
- Questions only when they bear on correctness, security, a behaviour claim made in the PR, or a fix decision.
- Paul's own notes (`(My note)`) unless the agent's research answered them with "no change needed".
- Description fixes only when the body would mislead an approver, is plainly stale, or holds the test evidence.

**Leave unticked (decline)**:
1. Rollout, deploy or merge order, flag soak time, rollback lever, prod-data checks, release gates. Decline these even when they're marked blocking. He treats them as the author's job or his own.
2. PR title, description, template, ticket or PCI-section hygiene; screenshot or design-sign-off nags; manual QA evidence (unless it is tied to an unverified behaviour claim).
3. "Is this intended?" product-intent questions that need no code change; speculative race or contract questions.
4. Pre-existing or out-of-diff issues; code about to be deleted; fixes that are really follow-up refactors.
5. Questions about another repo's implementation, or about the scope of sibling PRs. Exception: a cross-repo question that bears on a security goal.
6. Points another human reviewer already raised.
7. Product copy decisions.
8. Asks that add a new CI gate or an ongoing maintenance burden.
9. Paul's personal style rules that are not repo rules (for example em dashes in code comments).
10. Paul's own notes, or `@cc` questions, that the agent answered with "no change needed".

## Other option types

- **Bundles** ("post all", "suggestions only", "notes only", "approve with nits attached"): never tick. Tick the individual items instead.
- **"Ask the author the open questions"**: never.
- **Follow-up tickets for Paul to raise, and Linear bookkeeping**: never. Asking the author inline to raise one is fine when the finding is load-bearing.
- **Reply to Slack questions**: never.
- **Replies on bot or other-reviewer threads**: tick when the reply adds something new. Skip agree-only replies.
- **Resolve options**: tick only when the fix is verified. Leave threads the author declined open for Paul. At the end of a long cycle, accept the author's position and resolve rather than escalate.
- **Pick-one variants**: prefer per-finding inline over combined or summary variants, one consolidated comment over many repeats, and the minimal "leave as built" choice when there is one.

## Leave for Paul

Leave these unticked and list them under `For Paul:`:

- A "decision that is yours" design or product choice that has no minimal option.
- A design-level disagreement where the approach itself is contested. His pattern there is one design comment instead of line findings, which the doc's options rarely offer.
- An approve withheld only because another team owns the area, phrased as `Deferred to <Team>. Approve anyway?`
- Any approve tick that would conflict with a standing withhold.
- A security PR with an open telemetry or security question that the doc says he raised.
