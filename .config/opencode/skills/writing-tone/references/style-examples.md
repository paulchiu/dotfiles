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
