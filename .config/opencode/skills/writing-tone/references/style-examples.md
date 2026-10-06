# Style Reference Examples (Long-form)

Worked examples for longer-form posts. Each shows the message body plus structural commentary on what to absorb. Quick voice anchors for short messages live in `SKILL.md`.

---

## 5. Retro card / structured analysis

The challenge is that by immediately going to the team with 'well done on Q1, here's all these time-sensitive things for Q2', we're not setting a sustainable pace. For most teams with Q2 commitments, AFAIK they haven't been adjusted, and we're effectively fitting a quarter's worth of goals into two-thirds of the time.

I understand the theoretical argument: AI-enablement 'in theory' doubles velocity, so two remaining months gives you four months of pre-AI capacity. But it's unlikely to work that way. Even if it did, the mental toll of effectively telling people 'you need to do three months of work in two months', before they've had the chance to prove that enhanced velocity for themselves, IMO leads to increased delivery anxiety.

Question for the group: how do we set expectations and pace for teams coming off a heavy Q1 into a shortened Q2.

---

## 6. Broad-audience announcement / update (e.g. #broad-announce)

We identified that as our streams have matured, domain knowledge has increasingly concentrated within individual teams. That's somewhat expected, but it limits how quickly people can grow across domains and makes us more fragile when priorities shift. To address this, we're trialing cross-stream secondments as a way to deliberately move knowledge between streams, support individual development, and build broader platform context across the org.

[...lessons learned section...]

Next steps: if a secondment or cross-stream rotation is something you'd be interested in, or if there's a domain you've been wanting to build experience in, I would encourage you to raise it with your manager as part of your next career development conversation. We're interested in making this opportunity available to all engineers, and having a pool of interested people make it easier to facilitate secondments.

---

## 7. Inline blockquote reply to a sensitive 1:1 message (DM, point-by-point)

> I know the reviewers mean well [...] but sometimes the feedback lands in a way that feels dismissive of the effort.

AFAIK this is broader feedback that the review team is actively working on. Recent deadline pressure may have caused a regression.

> I'd also appreciate more visibility into the upstream planning work [...] so I can form a view on things before they land.

What would your preference be for this. I can think of a couple of options...

1. Async, I can set up a private `planning-notes` channel where Bob and I share scoping threads and early context.
2. Sync, I'd invite you to the planning meetings we already attend.

Generally we don't do option 2 because you'd end up in a lot of meetings with no relevance to your current work, and it turns your day into a manager's schedule, but you'd still have normal delivery expectations.

> I feel like I can't bring my whole self to work at the moment [...] and it's making it hard to do my best thinking.

Yes, [emotional dissonance](https://pubmed.ncbi.nlm.nih.gov/10412221/) has known negative effects. I don't think there's a short-term intervention for this, it's something you have to feel over time; we'll check in on it in 1:1s to make sure things are moving in the right direction.

> I don't know if I qualify for wellbeing leave [...] I've been second-guessing whether to ask.

I'm not really qualified to judge eligibility. The company treats it as an aggregate signal of team health, not as an individual identifier; they're aware uptake has increased recently and are looking at why.

Practically speaking, if you ever want to take it and aren't sure how to frame it, just tell me 'I need a day' and lodge the leave, that's enough.

> Thank you for listening.

Appreciate that. Ideally we'd cover most of this in our 1:1, but with Focus Week we most likely won't catch up until May. I can always book something in if you want to chat sooner.

**Demonstrates:** truncated `[...]` blockquotes, leading with information not validation, numbered options with explicit tradeoff explanation, citing external research, acknowledging own expertise limits, facts/policy as reassurance over personal vows, blunt practical instructions, functional sign-off with operational context.

---

## 8. Quick consent-check DM to a peer (ask BEFORE context)

FYI I'm going to spin up a shared `triage-notes` doc where we can drop weird tickets we want a second opinion on. Editable by both of us, no expectation to read every entry, just skim when you have a minute.

Any objections before I set it up.

Context: a couple of themes from recent on-call handovers point to overlap on tickets we're both ending up on. Hopefully low-effort on our end since we're already seeing most of these.

**Demonstrates the structural pattern for peer consent-checks:** no salutation, 'FYI' as an inline opener (no colon), plan and mechanics up front, the ask lands before any rationale, 'Context:' paragraph at the tail so the reader can stop at the ask if they trust you, 'Hopefully' hedging the effort claim on someone else's behalf. **NOT here:** a 'Hey [Name],' greeting, a 'Background:' preamble before the ask, an explanation of why this matters before naming the thing.

---

## 9. Channel recognition / high-five post (e.g. shoutouts channel)

:highfive: High five to @Ivan for the prep that set up our ORM migration stream for a running start :rocket-dash:

We were faced with a rather intimidating brief: a full backend migration off the legacy ORM across `platform` (API), with services of varying complexity and risk. Ivan worked through the shape of it and delivered:

- A phased plan document for the backend changes, which the team adopted in kick-off yesterday as our source of truth.
- The consolidation and scoping tickets that Carol and I are now picking up.
- A `billing-service` walkthrough with integration tests, giving us a concrete reference for the confidence bar we want on every migration.

On top of the planning, he's been steadily merging early PRs across `platform` while the rest of us were still at Focus Week.

Thanks Ivan for :ship-it:

**Demonstrates:** channel-native marker emoji (`:highfive:`) rather than a generic stand-in, a playful trailing emoji reinforcing imagery from the opening line (`:rocket-dash:` after 'running start'), narrative opening framing ('We were faced with a rather intimidating brief') rather than detached assessment, repo-level name with a parenthetical qualifier (`platform` (API)) over team-internal jargon (`platform-api`), specific dated company event ('Focus Week') as the vivid stand-in for 'what the rest of the team was doing', credit list naming only people in the source (Carol and I), and casual sign-off where the value emoji plays the role of the noun being thanked for ('Thanks Ivan for :ship-it:'). **NOT here:** fabricated participants for narrative symmetry, generic value-tying closers ('truly embodies Ship It'), effusive intensifiers ('absolute gun', 'massive props').

---

## 10. Consolidated thread reply addressing multiple posts (one message, inline blockquotes, self-questioning)

> really thoughtful and considered way of communicating and I thought what he decided to share was on point from an audience perspective.

I think I may have been a bit harsh and read his thoughtfulness as hesitancy. Which in itself is not a problem, but the types of questions he asked were definitely more technically leaning. For a solution design exercise, what we're looking for is someone that at least confirms they have the right idea and is building the correct thing first.

Where there was a positive signal was when asked things about how he would scale the system or how he would work with either scope or timeline changes. He responded with a sort of change checklist of the normal things you would do. So I think he either has experience or knows how to talk like an experienced person. Unfortunately I would say the thoughtful and considered communication didn't necessarily come across in a design discussion context. It's also possible that he was too thoughtful about it and tried to play to an engineering manager context, managing a manager audience, when part of what we're looking for is product engagement as well.

> Is it worth considering Zhangbin for a *senior* role in Spots?

At senior level, yes, I think Zhangbin is worth considering. Scott did mention that for some of the observations I mentioned we would normally prove or disprove it at the pair programming exercise stage. So I think it's worthwhile to at least see how well his knowledge translates to implementation.

**Demonstrates:** one consolidated reply addressing two different posters in the same thread rather than two separate messages, short quotes left whole rather than truncated with `[...]`, leading with self-questioning ('I may have been a bit harsh and read his thoughtfulness as hesitancy') before re-asserting, concrete recall of what the candidate said ('change checklist of the normal things you would do') over abstracted categories ('the standard scaling levers'), steel-manning the alternative reading ('It's also possible that he was too thoughtful and tried to play to an EM context'), surfacing institutional knowledge from a side conversation ('Scott did mention that...'), and grounding the recommendation in the next concrete process gate (pair programming) rather than speculating about team fit. **NOT here:** an 'Interesting divergence.' framing opener, a 'Keen to hear Adrian's take' forward-looking closer, manager-y verbs like 'push him through', or speculative fit framing about team shape.

---

## 11. Sentiment-share post to peer leaders (e.g. PLT engineering channel, mood update across the team after recent initiatives)

Hi team,

Wanted to share what's surfacing in CAD 1:1s this week on three recent events: AI-pril, Clean Kitchen, and the Fox announcement.

## AI-pril

Net positive. Most engineers described concrete wins (Datadog triage in minutes instead of half-hours, measurable noise reduction, the relief of being 'officially allowed' to spend time learning rather than feeling guilty about it). The more advanced users see it as the best change to their working environment in years.

The caveats cluster:

- Pace fatigue from the engineers who leant in hardest. Some have temporarily stepped back from AI tooling; others link the team's velocity to the recent incident pattern.
- Second-hand 'AI burnout' references, with engineers asking for clarity on what the next few months actually look like.
- Skill atrophy was mentioned. Hands-off delegation breaks the feedback loop you'd normally use to grow as an engineer; the open question is how we keep that loop alive while leaning in.

## Clean Kitchen

Strong sentiment from participants, including 'most fun thing this quarter' type comments. Cross-team exposure was singled out as a real win (sitting in other teams' standups, working in unfamiliar repos, building a sense of who looks after what).

The pain landed adjacent rather than inside:

- Stability fallout for teams not directly involved. A `node-24` change went in without a clean build and stayed broken for days; monitoring channels are noisy enough that several of us have stopped reading them, which is its own problem.
- Spillover pressure on engineers who weren't on Clean Kitchen but felt the 'extra time' framing applied to them by association.
- FOMO from engineers who wanted in but were assigned to deadline work.

## Fox announcement

Excitement about the product is genuine and broad. The concerns are entirely about expectation-setting around it.

What's coming up repeatedly:

- 'Prototype or production'. Engineers haven't seen the code and want to know whether the quality bar holds at scale, especially if patterns get pushed back into the main platform.
- The 'cracked team of engineers' framing landed poorly with at least one engineer. The read was, are the rest of us not cracked enough. Easy to dismiss but worth flagging.
- Velocity-as-benchmark anxiety. Worry that product partners will see what Fox built, assume 'a few words and it's done', then ask why a normal two-day request is taking longer. Fox as 'living proof it can be done super quick with limited resources' is exactly where the anxiety comes from.
- Job-security undercurrents. The small-team-big-output shape prompted direct questions in 1:1s about whether existing teams stay intact and whether restructuring is on the way.

I've been offering thoughts on the last two of: Fox is a best-case scenario rather than a benchmark, and patterns won't translate immediately because legacy stack, customer impact, and review/CI/CD bottlenecks are real constraints Fox doesn't have. I've also reassured directly where the headcount question came up, since AFAIK there's no restructuring (in downsizing sense) conversation happening.

**Demonstrates the sentiment-share post structure:** a 'Hi team,' anchor, a one-line framing opener stating what the post is, three sections each with a one-paragraph headline read followed by clustered observation bullets, and a closing paragraph that surfaces the manager's own 1:1 context-setting without converting it into a 'What I'm doing with it' / 'Next steps' section. **Specific patterns:** proper-noun fidelity ('AI-pril' as branded, not 'AI-April'), concrete nouns ('three recent events' not 'three of the recent moments'), neutral noting verbs ('Skill atrophy was mentioned' not 'the only concern that landed cold'), selection-implied negatives reframed factually ('wanted in but were assigned to deadline work' not 'weren't selected'), collaborative verbs over PR-register ('offering thoughts on' not 'counter-messaging'), disambiguated reassurance ('no restructuring (in downsizing sense)' not blanket 'no restructuring'), AFAIK used sparingly. **NOT here:** a 'What I'm doing with it' / 'Next steps' section, an open-invitation closer ('useful to compare notes', 'happy to dig in'), a presumptuous bridging opener ('some patterns likely cross PLT lines'), or operational-status follow-ups about EM feedback being collected and Q3 follow-up dates.

---

## 12. Product-share / community-announce post (e.g. forum launch, plugin beta)

## Disclaimer

- Is this project open source? **Yes** (MIT, source on GitHub)
- Is this project completely free? **Yes** (no paid tiers, no telemetry)
- Is this project vibe-coded beyond the author's ability to comprehend how it works? **No**

## Why I made it

I got sick of looking for iOS workout trackers that weren't buggy or full of ads. I wanted a workout tracker where the source of truth was Markdown in my own vault, with a proper structured editor instead of hand-typing inline fields. FitKit is what I use to track my workouts now.

## What it does

FitKit tracks workouts as plain (well, Dataview supported) Markdown notes in your vault. Data lives in Dataview inline fields so it stays readable and portable, and FitKit gives you a structured editor on top for daily entry of sets, reps, weight, duration, and rest timing.

![Workout editor, designed to be mobile friendly too](upload://example1.png)

The 'kit' is a small set of pieces that work together (path can be configured):

- Workout notes in `Fitness/Workouts`.
- Exercise notes in `Fitness/Exercises`.
- A generated `Fitness/Fitness Dashboard.md` with PBs and recent-session tables.

![Fitness dashboard to view your exercises and workouts at a 'glance'](upload://example2.png)

## What would help me most from testers

It's a beta, currently 0.15.2. Things I'd love eyes on:

- Mobile entry on iOS and Android, especially how the editor feels on narrow widths.
- Vault layouts where the default `Fitness` root or generated dashboard bumps into existing notes.
- There are some known missing features (like repeat workouts) that I don't use, but would like to know if they'd be useful to others.

## Installing

1. Install BRAT from Obsidian's community plugins.
2. Add the FitKit repo as a beta plugin: `https://github.com/paulchiu/obsidian-fitkit`
3. Make sure Dataview is installed and enabled too.

## Links

- Repo and issue tracker: `https://github.com/paulchiu/obsidian-fitkit`
- Licence: MIT

## AI disclaimer

I use Claude Code and Codex day-to-day on this. I read every diff, set the architecture and the `AGENTS.md` conventions the agents follow, and review PRs myself. If you raise something in this thread or on GitHub, I'll personally respond.

**Demonstrates the product-share post structure:** Disclaimer → Why → What → Tester asks → Install → Links → AI disclaimer ordering, with personal motivation leading and the AI footer trailing. **Specific patterns:** pain-point opener ('I got sick of looking for iOS workout trackers that weren't buggy or full of ads') landing the reader in the problem before any abstract benefits, self-aware parenthetical asides ('plain (well, Dataview supported) Markdown', 'path can be configured') that surface caveats inline rather than deferring them, image captions that name the artefact plus one beat of personality ('designed to be mobile friendly too', 'at a 'glance'' with the existing scare-quote convention), known-gap framing as an audience question ('would like to know if they'd be useful to others') instead of an apology or a roadmap promise, 'agents' over 'assistants' for current AI coding tools, minimal AI disclosure focused on ownership and response commitment. **NOT here:** an AI banner at the top of the post, safety-net detail in the AI section (adversarial review pass, CI gate of build/tests/lint/format), design-rationale jargon for general audiences ('the dashboard rebuilt itself from the notes rather than the other way around'), precious closers performing dedication ('FitKit is what I use every session'), or marketing-verb image captions ('beautifully crafted workout editor').

---

## 13. Delegation / agent-work debrief reply to a peer-leader (memo-style, multi-example with per-example lessons)

RE: standup delegation details

The concrete examples I had in mind were the last couple of agent-heavy pieces I picked up.

*CAD-1449 / CAD-1706 `posDiscountId` data inclusion in POS payloads change*

- PR #3518 was opened on the 30th of April and merged on the 4th of May.
- It then needed #3591 the next day to narrow the change to INFOGENESIS integration only.
- PR #3604 followed on the 6th of May as the final polish, dropping leftover `Object.assign` Venue clones.

*CAD-733 invoice generator*

- PR #2226 merged quickly in wall-clock terms, about 10 hours after opening, but it had 46 review events.
- The polish PR #2227 was closed after being folded back into #2226; this was my mistake in splitting/stacking. The lesson is that team members want pull requests to be a polished piece of work, and polishing can't be a separate phase as nit-pick comments will happen if you don't include it.
- The E2E PR #2229 is still open and rolled in more polishing comments.

This one is the clearest example of 'designing through PR' for me: live preview, print/PDF shape, tax registration copy, CSV behaviour, navigation, reset behaviour, and e2e shape were all still moving while the PR was under review.

*Lessons*

The LLM conclusion is that delegation works best when the acceptance criteria and review boundaries are tight enough that the agent can produce the right diff, and reviewers can reject out-of-scope churn.

When the issue is still being designed, the cycle time can quickly blow out with our long build times.

**Demonstrates the structural pattern for a memo-style debrief reply:** `RE: <topic>` subject-line opener (memo style for a known follow-up, not a prose 'Quick update from...' warm-up), one-line lead-in pointing at the examples, then each example lifted into its own `*Section title*` block with a brief descriptive phrase (`*CAD-1449 / CAD-1706 posDiscountId data inclusion in POS payloads change*` not bare `*CAD-1449*`), per-example bullets that stay tight and only carry the salient facts, the lesson attached at the point in the section where it came from ('this was my mistake in splitting/stacking. The lesson is that...') rather than collected at the bottom, a closing `*Lessons*` block in paragraph form (not bullets) holding the cross-cutting conclusion, direct first-person ownership of the misstep ('this was my mistake'), self-tagging an AI-generated framing the author kept ('The LLM conclusion is that...') as a transparency move, and a final lesson anchored in a named local factor ('our long build times') instead of an abstract principle. **Also note the backtick scope:** `posDiscountId` is backticked because it's a literal code identifier; ticket IDs (CAD-1449, CAD-1706), PR numbers (#3518, #2226), and the integration name spelled in prose (INFOGENESIS) all stay in plain prose. **NOT here:** dense diff/commit/line-count statistics ('+758 / -96 across 14 commits', 'about 1000 added lines'), a synthesised cycle-time metric ('roughly five calendar days from first pickup to final merge'), a 'My read is that...' diagnosis paragraph collected at the bottom, or an abstract closing principle ('the review and rework cost just moves into the PR') without a local anchor.

---

## 14. Peer-leader meeting-outcome update (memo-style: surfaced issue, action items, next steps)

RE: Engineering onboarding walkthrough with Alice

Following the retro topic of design onboarding, a peer leader suggested I walk Alice through how engineering onboards new starters. We did that this afternoon. Quick summary of what came out of it and where we'd like to take it.

**Key thing we surfaced: environment setup**

Alice hit permission blockers trying to set up a proper local dev environment and got steered fairly hard toward the lightweight sandbox instead, with little support for the full setup. The current dev-setup docs assume an engineering account and break for that group.

Alice's preference (and I'm happy to support) is for designers to go through the full local environment from the start, not the sandbox shortcut, so we're future-proofed for designers owning the design system and associated Storybook.

**Action items**

- Designers to go through the full local dev setup: Alice, Bob, Carol, plus a (technical) new designer when they start.
- CAD to assign buddies to support Bob and Carol through full setup.
- Fix the dev-setup docs for the product design group so they're followable step by step for a non-engineering account.
- Capture the product walkthrough: Alice is participating in an intensive session with Dave and Erin across all products and recording it for reuse. There are older recorded product videos floating around but they're a few years stale.
- Stand up a designer home in Notion: I shared the old design space, and encourage the current design group to claim or create their own space to share knowledge.

**Next steps / where we'd like to go**

Tactically, CAD is happy to support the 'co-contribution training' piece now (buddies for setup, plus a gentle first task). My pitch on the first task: don't have designers touch production first. If their domain is the UI/component library, a small Storybook tweak that they then watch get released teaches the lifecycle with very little risk.

The principle we use in eng is that first and second tickets are deliberately trivial, so the new starter goes through the motions without having to prove competency. Ideally we have something similar for designers.

The bigger ask is on Alice: I'd encourage new designer onboarding to be designed as a deliberate new-starter journey (each piece feeding the next toward a capability), rather than us piecemeal-ing nice-to-knows. Once the broad strokes exist, I can slot in where CAD fits and code contribution training sits.

Posting here for visibility. If anyone has thoughts please feel free to share, otherwise I'll move on to trying to action my parts in the coming weeks.

**Demonstrates the structural pattern for a peer-leader meeting-outcome update:** the same `RE: <topic>` subject-line opener as the debrief reply (example 13), used here even though the audience is a whole peer-leader channel rather than one person (a walkthrough that a leader asked for in a retro is a known follow-up), so it gets the memo opener, not a 'Hi team,' anchor or a `👋` greeting. Body is three labelled blocks: the single issue worth surfacing, the action items, and the forward-looking next steps. **Specific patterns:** no background/justification section, since the audience shared the retro context, so the post leads straight with what was surfaced and never explains the program's philosophy, history, or headcount ('CAD owns onboarding for the whole org', '18 engineers last year', 'we've churned through three designers') even though all of that was discussed in the meeting; supportive endorsement framing when backing a peer's call in their own domain ('Alice's preference (and I'm happy to support)' not '(and I agree)' or 'Alice's strong preference (and I agree)'); a neutral, fault-free statement of the technical cause ('the docs assume an engineering account and break for that group') with no blame or root-cause callout assigning fault to how access was provisioned or 'marketed'; plain-bullet action items (not `- [ ]` checkboxes; Slack doesn't render them and they imply a tracker the post isn't); tight one-line action items with the justifying asides cut ('designers will need more hand-holding than engineers', 'this is how our eng docs got good', 'the new JD goes out next week'); enablement framed as empowering the group to own it ('encourage the current design group to claim or create their own space') rather than enumerating everything you'll personally hand them; a closing that takes hedged personal ownership of your own follow-through ('I'll move on to trying to action my parts in the coming weeks') over a collective-momentum claim ('we'll get moving on the setup support'), and a polite open invitation to the group ('please feel free to share') over a casual 'shout'. **NOT here:** a 'Context' / background paragraph justifying the program before the substance, an emoji-and-greeting opener ('Hey PLT 👋'), checkbox-style action items, per-action justifying parentheticals, a list of everything-a-designer-should-know appended to the end (scope the post to what was decided, not the full brainstorm), or a closing that claims shared momentum instead of owning your own parts.

---

## 15. Cross-team process question (why do we do X, is it intentional, anyone opposed to changing it)

Hi team, I'd like to understand the context behind our Crew release notes on the app stores.

My understanding is that every Crew release goes out with the same generic "What's new" text. Carol mentioned it's a note Dave provided that gets copied across each release. For example, 8.7.3 went out on the 20th of September with the standard note and no mention of crew discounts. I'd like someone to confirm whether that's the case.

If it is, could someone provide context as to why we do it this way, and if it's intentional for a reason? A possible reason I could think of is to limit the number of questions we get when venues see a new feature listed, but there may be others I'm not aware of.

Bob has suggested that the team doing a release should be filling in the notes with what's actually going out in it. I'm wondering if anyone is opposed to this process change?

**Demonstrates the structural pattern for asking a team about a process they own before changing it:** 'Hi team,' anchor plus a one-line statement of what you'd like to understand; the current understanding with its source named plainly ('Carol mentioned') and one concrete, dated example; a confirm ask; then the real question posed as a question with a '?', covering both 'why' and 'is it intentional'; one hedged guess owned in first person with room left for reasons you don't know; the proposed change attributed to its proposer as a shared 'should'; an objection check as the closer. **Specific patterns:** 'our Crew release notes' keeps the ask collaborative even though another team runs the process; the brief's framing ('per Chesterton's fence') is translated into the plain question it implies rather than name-dropped; the literal UI label takes double quotes. **NOT here:** 'per Chesterton's fence I'd like to know why before we change it' (named principle as copy, and a statement where a question belongs), 'One possible reason is' (unowned guess), 'the Crew release notes' (distancing), or a trailing logistics line the owning team already knows ('The notes are fixed once a release is published, so the next Crew release is the earliest we could try this').

---

## 16. Heads-up DM to a manager back from leave (what I tried, how it escalated, where it stands)

Hello, hope you had a good break, and welcome back :blobby-wave-2:

FYI and heads-up on something that came up while you were away.

Going into Q4 prioritisation with Bob last week, I tried to apply your guidance (at least two options per problem, and mapping what doing it properly would take before defaulting to a shortcut). For a non-trivial item like multiple loyalty offer engines, I planned for up to 2 weeks of elapsed time (not full work time) to map options and run them past custodianships and you. I framed it as the worst case for planning purposes, so any discussion doesn't push the rest of the quarter out like it did in Q3.

Unfortunately Bob didn't take it well and saw it as doing work for the sake of work (he compared it to team-nova planning 'by the hour'). He ended the meeting saying he would call Dave and flag it with Dave and Carol before we continue prioritisation. From there:

- That evening, Carol messaged me asking about 'this 3 options minimum mandate, was this from [you]?'. I corrected it to at least 2 and shared an AI summary of your guidance.
- Carol's view was that it's 'clearly not something Dave or Bob agree with so we will need alignment before we proceed', and that a one-team mandate feels uncomfortable to her.
- About an hour later Bob asked if Carol had reached out, and said he had also asked Dave to talk to you about not adding unnecessary time for alternative solutions.
- Yesterday Bob told me Carol is 'going to intervene and put an end to this endless and pointless battle / debate' about how much scrutiny our team needs.

In the meantime Bob and I are still working through Q4 picks, with a follow-up on Friday. A few estimates are on hold until after your catch-up with Carol.

**Demonstrates the structural pattern for briefing a manager on something that brewed while they were away:** a warm welcome-back with a custom wave emoji and no name (it's a DM), then a bare one-line 'FYI and heads-up' with no justification of why they need it; a 'what I tried' paragraph that ties the action to the recipient's own guidance, concretely; the other party's reaction introduced with a plain reception clause ('Unfortunately Bob didn't take it well and'); a relative-dated bullet timeline ('That evening', 'About an hour later', 'Yesterday') with short verbatim quotes in single quotes so the recipient sees the escalation in the other parties' words; a current-state paragraph as the closer. **Specific patterns:** the planning buffer is justified by the quarter's outcome ('so any discussion doesn't push the rest of the quarter out') rather than by the recipient's past redirects; the initiative name carries its domain ('multiple loyalty offer engines'). **NOT here:** 'Hey [Name], welcome back.', 'since it will likely come up in the catch-up Carol is booking', 'on the 24th' or 'about 5 hours after the meeting', 'and offered Bob two estimates, one with that step and one without' (a side concession that dilutes the thread), 'You haven't reviewed that summary, so it may not fully match what you meant' (pre-emptive disclaimer), 'so a late redirect doesn't push...' (casts the recipient as the cause), or a closing stance paragraph ('I'm not trying to take a side here... Mostly I'd like you, Dave and Bob aligned').

---

## 17. Repair follow-up DM to a peer after a heated exchange (own the phrasing, clarify intent, appreciate their shift, shared way forward)

RE: yesterday morning

To follow up on this, after some thought, I think my word choices could have been better.

To summarise and clarify, my questions were asked with an underlying intent of wanting to understand the domain and context, and not intended to come across as an audit or making things more onerous; but I can see how it came across that way.

I appreciate you giving the IdealPOS opportunity a look, and working through the ranking with me.

On the Frank situation, I think I'll defer my thoughts on that some more and wait for the outcome of his chat with Carol; I haven't heard anything so far today (Wednesday).

Hopefully we've found some common ground with how we position our suggestions going forward, and can avoid misunderstandings about intent and process in the future. Looking forward to the follow-up on Friday.

**Demonstrates the structural pattern for repairing a working relationship after a sharp Slack exchange with a peer:** memo-style 'RE:' opener because it fulfils a promised follow-up; five short paragraphs, one job each. Ownership sits at the level of word choice and is hedged ('I think my word choices could have been better'), with no itemised offences and no explicit 'sorry'. Intent is restated as the writer's own goal ('wanting to understand the domain and context') and paired with a concession on impact ('but I can see how it came across that way'), echoing the other person's complaint in plain words ('making things more onerous') rather than quoting it. Appreciation is plain thanks for the two specific things the other person did, with no comment on how they did it before. The promised follow-up on the third party (Frank's guidance, which the writer can't control) gets one line that defers to someone else's outcome and gives a factual status, closing the loop without taking a position or leaving silence. The closer is shared and hedged ('Hopefully we've found some common ground'), then the next touchpoint as a functional sign-off. **NOT here:** 'Calling you defensive didn't help either, sorry about that' (re-names the offence), 'My 'on' mode lands a lot harder over Slack than in person, so I'll work on that' (self-diagnosis plus a personal vow), '(I wasn't channelling Frank)' (drags the third party into the writer's own intent), 'I do want to acknowledge and note that I appreciate your change in approach throughout the day' (implies their earlier approach was the problem, and stiff), leaving the promised third-party follow-up unmentioned, 'mostly me trying to get my head around a domain I don't know well' (colloquial where the brief's 'casual' meant 'no quotes'), a three-item list of their gestures ending in a terse 'Appreciate it.', or 'Going forward I'll keep anything new in the candidate pool [...] Let's use Friday 2pm to agree how we want to run Q4 prioritisation' (unilateral concessions and a prescribed agenda).

---

## 18. Handover FYI DM to a peer manager (own a past judgement call, grant them authority over it, offer to explain to affected team members)

Hey,

FYI on the GrowthOS ratings you're inheriting from me for much of STAB... For this round of check-ins I've changed my approach, and I'm no longer rating anyone more than one level above the level they're on.

Looking back, a lot of the higher ratings I gave in the last check-in came from a superficial read of each behaviour in the career framework, and I didn't have much evidence to back them up. They'll carry forward into this cycle, so please discard them freely.

If any team members feel the 'downgrade' of a capability is unfair, they're welcome to reach out to me. I'm happy to explain my reasoning for revising their assessments.

**Demonstrates the structural pattern for handing a peer manager something you got wrong before they took it over:** 'Hey,' with no name (a cold 1:1 DM), then 'FYI on' naming the thing and the team it covers ('for much of STAB'); the new approach as one plain sentence; a 'Looking back' paragraph that owns the old call in first person and names the gap concretely (superficial read, little evidence), then the practical consequence for the recipient ('They'll carry forward into this cycle') and a single grant of authority ('please discard them freely'); a closer that offers the affected team members a route back to the writer, with 'downgrade' in single quotes because it is their likely framing. **NOT here:** 'Hey Michael,' (the DM already names him), '...inheriting from me.' with no team named, 'please discard them, and feel free to clear them and set your own assessments' (stacked permissions spelling out how to do his job), 'I'd be more than happy to explain my reasoning and justification' (intensifier plus a near-synonym pair).

---

## 19. Peer-guild proposal share asking for early direction (problem, session credit, AI;DR, emoji vote, PS/PPS, cc)

Hello brain trust,

I have something I would like to get an early direction on from the group.

The problem #stream-responsive-roadmap are trying to solve is letting an organisation run Toggle gift cards alongside a separate loyalty offers provider (e.g. Hall & Woodhouse want Zonal Vouchers for offers).

Last Friday I had a brainstorming session with @Alice, @Bob and @Carol.

:claude-code: has written up the sessions ideas on how we could support a separate offers provider and gift card provider per organisation.

_AI;DR_

Toggle currently (controversially) leverages the loyalty promo code path to support its gift cards, so it takes the organisation's only loyalty slot. To add support for an offer provider alongside, we have...

- Option A, add a new composite loyalty provider behind one loyalty program: no schema change, but the gift card stays lumped into the loyalty line and is applied before fees. This is the fastest method, but is pretty hacky.
- Option B, enable setting a type on each loyalty program (`LOYALTY` or `GIFT_CARD`): an 'Add gift card' row in the guest app, and the gift card applied last on the remaining total. This is the recommendation from our Friday session.

The attached HTML has the agreed (between RR and LOY) model, current limitations, and side-by-side flow and schema diagrams for each option.

Are people happy with option B directionally? Feel free to react or add thoughts in :thread:

:one: Happy with B
:two: I have alternative ideas or preferences
:three: Needs more discussion in a sync session

PS I've attached HTML rather than a Notion page as I find it's easier to compare the flow charts and DB changes, but happy to move it to Notion if people would like to leave more detailed comments.

PPS We know there's an outstanding issue with gift cards being applied as discounts, and with where service charges sit in that ordering. We (RR) plan to address this separately to keep discussions focused.

cc @Dave @Erin

**Demonstrates the peer-guild proposal share:** a warm group greeting, then a one-line statement of what kind of input is wanted before any detail; the problem in one sentence, owned by the team's channel link rather than an ambiguous 'we'; the session attendees @mentioned inline so they don't need a cc; `:claude-code:` as the subject of the write-up because the agent drafted it; an italic `_AI;DR_` whose first sentence sets today's state (with a candid aside, 'controversially') and trails into the options with 'we have...'; option bullets that open with the action ('add a new...', 'enable setting a type...'), say what changes and the trade-off, and end on a candid verdict or whose recommendation it is (the session's, not the author's); a one-line pointer to the attachment that names the teams behind the agreed model; the direct question kept as a real question, with numbered reaction choices; a PS that owns the format choice in first person; a PPS that scopes out an adjacent known issue, says which team plans to handle it and why; cc reserved for stakeholders who weren't in the session. **NOT here** (all cut from the agent's draft): a generic 'Hey folks', 'I've written up' when the agent wrote it, a bold `*AI;DR*`, 'This is my recommendation', the migration and schema sentence, a shared-prerequisite bullet ('Both options need a Zonal Vouchers adapter'), a secondary clause in the problem statement ('while me&u discount codes keep working'), and a cc line repeating people already @mentioned.

---

## 20. PSA to product managers on the cost of a product decision (TL;DR on impact, long version bullets, hindsight-hedged counterfactual)

Hi folks,

Given 👆 PRs related to `fix(loyalty)`, I just want to post an FYI highlighting that some of our product choices can create unplanned cleanup work, with Toggle being the example.

TL;DR on impact: accepting Toggle gift card numbers through the promo code field meant card numbers guests typed into me&u were stored in our logs and analytics. Masking them needed 12 sub-issues across 5 services and about a week of elapsed time to address.

Long version...

- Guests apply a Toggle gift card by typing its number into the promo code field. Promo codes were never treated as sensitive (e.g. HAPPYHOUR for 10% off are effectively public), so we logged and tracked them without thinking too much about it. Unfortunately, once we started accepting gift cards, gift card numbers (possibly with balances) were stored in Datadog and sent to Amplitude. Example log line in [Datadog](...), with a screenshot attached.
- As to why this is a problem... a gift card carrying a balance should be treated like a credit card number. me&u only needs the number (no PIN) to spend it, so anyone who can read one in a log or an analytics event could drain its balance at any Toggle venue without the cardholder's authorisation.
- To fix this, we've had to mask card-shaped values everywhere they're logged or tracked. That took a spike to investigate, then 12 sub-issues and 12 PRs across `serve-frontend`, `serve-api`, `guest-gateway`, `loyalty-connector` and `loyalty-integrations` (with 2 small follow-ups still to land), over about a week from start to finish.
- If gift cards had their own input instead of overloading promo codes, (admittedly speaking with the benefit of hindsight) I hope we would've caught it sooner. Going by PCI compliance posture, we would at least isolate and tokenise numbers like this as early as possible post-input, so the rest of our systems only handle a reference to the card and any leak exposes far less.

cc [stakeholders]

**Demonstrates the cautionary PSA to a cross-functional audience:** 'Hi folks,' on its own line, then an opener that ties the post to the posts above and names which ones ('Given 👆 PRs related to `fix(loyalty)`') and states the general point with 'our' so the product choice is shared, not pinned on the readers; a plain 'TL;DR on impact:' line with both the scope and the elapsed time (Paul's own summary, so 'TL;DR' not 'AI;DR'); 'Long version...' as the bridge into the bullets. **Specific patterns:** an everyday example in a parenthetical that says why promo codes were never sensitive ('are effectively public'); the oversight owned as 'we' with a plain 'unfortunately' turn; a conversational lead-in naming the bullet's job ('As to why this is a problem...'); facts kept plain but not inflated ('card numbers (possibly with balances)'); the counterfactual hedged with hindsight and a hope, and the better practice stated as what we would do ('PCI compliance posture', not 'requirements'); lowercase 'cc' (the names are filled in at posting time). The 'what's still left' bullet (old log lines, analytics events, stored copies) was cut from this post only to keep its scope tight; include one by default. Effort is stated as the work and the elapsed time ('took a spike to investigate, then 12 sub-issues and 12 PRs [...], over about a week from start to finish'), not the spike's own estimate ('a 2 day spike'). **NOT here** (all cut from the agent's draft): 'Hi folks,' run into the opener, a bold '*Impact: ...*' line, 'our services logged and tracked them as-is', 'every card number [...] was stored in full', 'Masking them took 12 unplanned sub-issues' (repeats the opener's 'unplanned'), 'a 2 day spike to find the problem', 'most of this wouldn't have been necessary', 'the general practice is to isolate and tokenise', and 'CC'.

---

## 21. Reply to a reviewer's questions (thanks, TL;DR, quote-and-reply per point, one open ask)

Thanks for the review Kelly,

TL;DR Agree with rewrites, I've updated the concept (please see v2 attached) and added a checkout screen, with a question about whether we should use the venue's own service charge name in the heading.

> Manage 1. I assume the dashed line isn't on the UI? Is it also indented?

Yep, it was only there to show what's new, removed now and made to look more like what the implementation will be.

> Manage 2. Can we update the copy?

Done.

> Serve 1. There's not really a hover state, right? So how do guests actually view it?

Correct, there is no hover, my mistake. The intent is it works the same as the platform fee ⓘ today, so shown on tap. Concept updated.

I've also added the checkout screen. Guests can only remove the service charge from their cart, so on checkout the ⓘ opens the same sheet with just a 'Got it' button and one extra line: 'You can remove it from your cart.'

> Serve 2. Let's update the heading to `What is the service charge?` & body copy...

Done, and it lines up nicely with the platform fee's 'What is the me&u platform fee?'.

One thing I'm unsure about: the service charge name is whatever the venue types, with no length limit (results in EU production show names ranging from 7 to 85 characters), so a venue's 'Service Fee 12.5%' would still open 'What is the service charge?'. I'm leaning towards putting the venue's name in the heading with short 'Keep' and 'Remove' buttons (option C in the new section), since long names in the buttons get messy as long names wrap rather than truncate. Would appreciate your thoughts.

FYI ten EU venues have named theirs 'Service Charge (Click here to remove)' as a workaround, so we'd ask them to rename it once this is on.

**Demonstrates the reply to a reviewer:** 'Thanks for the review Kelly,' as the greeting; a 'TL;DR' line straight after it that agrees with the rewrites, says what changed with a pointer to the attachment, and flags the one open question so the reviewer knows there's an ask before reading on; each of the reviewer's points quoted with its label ('Manage 1.', 'Serve 2.') and trimmed to the question, with '...' where the pasted copy would repeat what's already applied; short answers that state the outcome ('Done.', 'Concept updated.'); the mistake owned in two words ('my mistake'); new work the reviewer didn't ask about (the checkout screen) added under the closest point as a plain statement, not a request for approval; the data claim names its source ('results in EU production show'); one genuine open question, ending 'Would appreciate your thoughts.'; and an FYI as the last line, with no sign-off. **NOT here** (all cut from the agent's draft): the reasoning behind each answer ('the other fields in Manage that show up when you flip a toggle sit flush, so it lines up with...'), evidence the reviewer didn't ask for ('see the recording, hovering only changes the cursor'), asking permission for a decision already made ('I'd like to drop it so both work the same. OK with you?', 'Does that work for you?'), 'live ones range from', 'What do you think?', a closing '---' line restating what was updated and attached, and the doc's changelog, evidence and follow-up sections.
