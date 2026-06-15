---
name: writing-tone
description: "Rewrite drafts and raw notes into polished non-code communication in the user's voice. Trigger for write/draft/rewrite/summarise/share Slack, email, updates, FYIs, or 'my tone/style/voice'. Skip commits, PRs, technical docs."
---

# Rewriting for Tone & Style

Transform rough drafts and unpolished ideas into clear, professional communication in Paul's voice.

## Pre-flight checklist

Re-check the draft against these before outputting (the most-violated rules; full detail below):

- No em dashes. Use commas, semicolons, parentheses, or separate sentences.
- Single quotes for scare quotes and emphasis, not italics.
- Australian spelling and quote style.
- Discussion and rhetorical questions end with a period, not a question mark.
- Lead with substance. No validation openers ('Fair point') or scene-setters ('quick one').
- End at the last real point. No wrap-up, summary, or evaluative restatement.
- Plain language over institutional terms. Cut intensifiers/filler (just, really, genuinely, actually) and generic difficulty markers (hard, tricky).
- Hedge verdicts, proposed causes, and predictions; state facts and existing precedents plainly.
- Name who owns what; attribute group decisions to the group; never invent names or facts (use [brackets]).
- Backticks only for real code tokens, not ticket IDs, PR numbers, or brand names.
- Match register to audience (DM vs broadcast vs peer-leader).
- Stick to the scope given; don't expand or add follow-up offers.
- Output only the rewritten message, no meta-commentary.

## Writing style

Rules are grouped into clusters; each is `directive ('X' beats 'Y') + carve-out`. When adding a rule, extend the right cluster's carve-out rather than appending a sibling.

**Register & word choice**
- Professional yet collaborative, medium formality (conversational but polished, not stiff). Direct but not absolute; use measured hedging ('is unlikely to be immediately observable' not 'doesn't hold in practice'). In team guidance/checklist/process docs, frame norms as shared 'should' rather than declared accomplished fact ('we should apply this to every issue' not 'this applies'; 'should be the exception' not 'is now the exception'; 'should pass code review' not 'would pass code review').
- Plain language over institutional terms ('the arrangement' not 'the program design'; 'two-fold' not 'two-pronged'). For family/non-technical readers, go plainer still: short sentences, one idea per paragraph.
- Casual abbreviations (AFAIK, IMO) fit DMs, retro cards, and leads channels; use sparingly in broad-audience posts. Don't abbreviate everyday words ('dependency' not 'dep', 'configuration' not 'config').
- Concrete, specific verbs and nouns ('once we've replaced TypeORM' not 'once we're through'; 'three recent events' not 'three of the recent moments'). 'Moments'/'things'/'moves' read as fluff.
- Match verb register to stakes. Casual verbs (bounce, punt, chuck, kick out) suit small asides but read as flippant for scope/escalation decisions to peer-leaders; use neutral verbs there (redirect, defer, exclude, move out).
- Avoid combative/PR-register verbs for what a manager does in 1:1s ('counter-messaging', 'getting ahead of' → 'offering thoughts on', 'sharing context that').
- Avoid prefix-coined verbs ('pre-mentioning', 'pre-aligning') when past tense already conveys 'in advance' ('I've mentioned this in sprint planning').
- Cut generic difficulty intensifiers on technical nouns ('technical calls' not 'hard technical calls'; 'an architectural question' not 'a tricky' one). Descriptive adjectives carrying specific content stay ('a thorny review').
- For AI coding tools, 'agents' not 'assistants'.

**People words**
- 'team members' not 'people' for colleagues. 'person'/'per-person' not 'head'/'per-head' when counting or costing colleagues. Addressing a subgroup directly in a broadcast, 'members' not casual collective nouns ('PH members, drop a 💬' not 'PH crew'); the casual noun is fine in descriptive narrative ('the PH crew do their own meal out').

**Asks & outcomes**
- Personal ownership for asks ('I would like to discuss' not 'We need to talk about'); position as request, not demand. Name the desired outcome explicitly ('to minimise stress on teams' not 'how we pace this').
- External support/experts: frame the ask around the outcome, not a guessed remediation ('let us know how we can onboard the new user' not 'confirm whether the invite needs reset'). Use 'please' for external parties; internal peers don't need it.
- Cross-team peer with co-ownership: open invitation around outcome and timeframe, not a prescribed venue ('let me know how you'd like to collaborate and cross-skill the team for the rest of Q2' not 'I'd like a few minutes in PLT stand-up'). The direct-ask carve-out is for your own work a peer can confirm/unblock, not shared planning.
- Hedge effort cost you're asking someone else to share with 'Hopefully' ('Hopefully low-effort on our end'); you don't know their load.

**Hedging & certainty**
- Hedge proposed causes for someone's behaviour or internal state ('a possible reason is', 'they may feel'), not 'My read is' or first-person certainty. Direct observation of what someone *did* stays direct; the hedge fires on *why*.
- Soften verdict-style closers with a conditional ('I would treat it as one signal, not proof' not 'I treat it as'). Soften assertive verbs in debrief contexts ('worth considering', 'I'd lean toward' not 'push him through', 'ship it').
- But don't over-hedge: name an existing precedent as the model plainly ('Prophets' V2 migration is the operating model' not 'the model worth pointing at'), and be blunt when advice calls for it ('ultimately you need to stand for what you think is right'). Hedging is for verdicts/causes/predictions, not facts or precedents.
- Acknowledge limits of your own expertise frankly ('I'm not really qualified to judge X'). Plain verbs for caveat lead-ins ('a few things to note' not 'to hold lightly'/'sit with'). Explaining a tool/option from research not first-hand use, hedge with everyday confidence ('seems legit and commonly used' not 'is legitimate and widely used').

**Openers**
- Lead with information, not validation; skip 'Fair point', 'I hear you', and soft-framing variants ('Interesting divergence.', 'Good point.', 'Worth noting that...'). Replying to a specific message, lead with the blockquote.
- Drop filler scene-setting openers ('quick one', 'got a sec', 'small thing'); open with the substance or 'FYI'. Carve-out: a one-line framing opener on a broadcast post is welcome (see Structure).
- Cut meta-commentary that performs an observation's value before making it ('What's interesting is...', 'the reason this is worth flagging is...'); state it directly.
- 'FYI' over 'Heads up:'; 'Context:' over 'Background:' for the short 'why'.

**Closers & wrap-ups**
- End at the last real point. No wrap-up, summary, or evaluative restatement (don't close with 'That's the definition of leading by example', or 'which is a critical dependency' when the facts already carry it). Don't explain reasons already obvious from context. Cut folksy aphorisms and cute self-referential reframes too ('Measure twice, cut once', 'that's the checklist doing its job', 'we'd rather hear it'); state the instruction plainly instead.
- Complete subject-verb closers, not gerund fragments ('I'll be booking the first slots this week' not 'Booking the first slots this week').
- Soft connector for closing reframings ('So... I guess' not 'That's the pattern, because'/'The real point is'), especially when speculative or for a thoughtful audience.
- Front-load epistemic humility with a compact phrase ('as an anecdote', 'one data point', 'rough cut') rather than only a later caveats block. Own refrains in first person ('recently I've shared in different conversations that X' not 'I've been hearing X anecdotally').

**Attribution**
- Name who owns what; attach a person to work ('Alice is on the Project Alpha work'), and include yourself in headcounts ('me + 4 engineers' not '5 engineers'). Attribute group decisions to the group ('we (Bob, Carol, Dave) agreed' not 'I've pulled...').
- Back another leader's call in their domain as support, not co-assertion ('Alice's preference (and I'm happy to support)' not '(and I agree)'/'strong preference').
- Relay sourced views by naming the people plainly ('Shawn and Miguel both feel that...' not 'there's consensus that...'); drop the credentialing parenthetical when the recipient already knows why you consulted them.
- Own your own failed decisions directly ('this was my mistake in splitting/stacking' not passive 'too much was folded in'). Applies to your calls only; group decisions still attribute to the group.
- Attribute AI-agent analysis explicitly when unverified ('Claude notes it looks like a `userEvent.clear()` race' not 'It looks like the classic ... race'); strip authoritative adjectives ('classic', 'textbook', 'the usual'). Restate in first person once you've verified it yourself.

**Framing people & judgement**
- Place the team in the scene over detached assessment ('we were faced with a rather intimidating brief' not 'the scope looked daunting'), especially in recognition/retro contexts.
- Neutral noting verbs for signal volume to peer-leaders ('skill atrophy was mentioned', 'came up', 'raised') not editorial superlatives ('the only concern that landed cold', 'the strongest signal'); frequency already weights it.
- Avoid ranking/selection-judgement framings when the reality is assignment ('wanted in but were assigned to deadline work' not 'wanted in but weren't selected'); use the factual reason.
- Lead with self-questioning when feedback diverges from your read ('I may have been a bit harsh and read X as Y') before re-asserting; steel-man the other reading.
- Avoid rhetorical contrast framing ('didn't just X; they Y'; 'not only X, but also Y') and the diagnostic variant ('the gap wasn't the fix itself; the requirement never carried...' → just 'the requirement never carried...'). State it as a straight list. Drop intensifiers/filler ('herself', 'actually', 'really', 'just', 'genuinely', 'exactly'). Carve-out: observational adverbs with specific physical detail ('looked visibly more blank') add information.

**Sensitive & interpersonal**
- Don't argue with self-deprecation ('I know this sounds irrational'); acknowledge briefly, go to substance.
- Reassure with institutional/factual context, not personal vows ('the company uses it as an aggregate signal of team health, not to identify individuals' not 'I would never judge you'). Don't assume the recipient's emotions ('if this sounds like too much trouble' not 'if you'd be stressed').
- Cite external sources where they add weight (e.g. linking [emotional dissonance](https://pubmed.ncbi.nlm.nih.gov/10412221/) on the cost of masking at work).
- Single-word marker acknowledgements ('Noted.', 'Heard.', 'Agreed.') for received-but-not-actionable points. 'please see https://...' not a bare colon before a URL.

**Group & channel addressing**
- 'someone' not 'you' for channel asks ('when someone gets a chance'). Frame whole-group input asks around the group ('two ideas I'd like everyone's opinions on' not 'your read on').
- Keep framing tentative when floating options for a group to choose ('they aren't necessarily either/or; we could rotate them' not 'the plan is to rotate'); carry it through verbs ('which one we try first' not 'run first') and closer ('I'll tally by Wednesday EOD and figure out next steps' not 'and book it in'). Tentative on the outcome, still concrete on the deadline.
- 'e.g.' prefix for illustrative parentheticals that are samples, not the full set.

**Caveats, clarity, self-positioning**
- Surface caveats as inline parenthetical asides at the relevant point ('plain (well, Dataview supported) Markdown'), not a deferred caveats section that reads as overselling-then-retracting.
- Add brief parenthetical context for ambiguous jargon ('`Spark` (their AI-optimised terminal emulator)').
- Trim self-elevating role markers when the audience knows your role ('more active tech feedback' not 'more active tech lead feedback from me'; drop 'on my end', 'as the EM'). Carve-out: keep the marker in cross-team/external posts where it disambiguates.
- Slashes for paired near-synonyms where neither word alone fits ('credible/confident'), sparingly. Avoid italics for emphasis ('it flips' carries on its own); carve-out: italics for paraphrased self-quotes/coined refrains ('it *feels like a 50% velocity bump*').

## Structure & format

**Prose vs bullets**
- Prefer flowing prose; use bullets only for genuinely discrete items, and don't bold within bullets. For personal advice, short paragraphs and snappy sentences; bullets for concrete steps/options/tradeoffs.
- Break multi-part updates by category, not one block (the scope/definition claim gets its own short paragraph; operational mechanics go in another) so a scanning reader takes the headline first.
- For multi-example posts (delegation debriefs, post-mortems), give each example its own Slack-bold subheader naming the thing, not just the ticket ID (`*CAD-1449 / CAD-1706 posDiscountId in POS payloads*` not `*CAD-1449*`). Attach each lesson to its example ('the lesson is...'); a final `*Lessons*` block can hold cross-cutting conclusions.

**Discussion vs announcement**
- In discussion contexts (retros, leads channels), pose the question to the audience ('Question for the group: how do we...') not a prescribed solution. In broader announcements, give a concrete next step ('I would encourage you to raise it with your manager' not 'I'd love to hear your thoughts').
- Open a retro card / structured analysis with the incident or substance directly, not a 'Context:' label (the opening description IS the context). 'Context:' still belongs at the tail of a DM.
- Frame section headers in incident/lessons-learned posts as forward-looking ('Advice for future changes', 'For the next migration') not backward self-assessment ('What we'd do differently', 'Mistakes we made'). The body can still describe what happened.

**Greetings, openers, sign-offs**
- Salutations are about cadence, not formality. In 1:1s/small threads, use 'Hey [Name],' only when reopening a cold thread; for ongoing conversations skip the greeting and open with 'FYI' or substance. Carve-out: 'Hi team,' is welcome on a broadcast post as an anchor.
- For broadcast posts (incident writeup, retro share, lessons-learned), a one-line framing opener warms the room ('Just wanted to share some lessons from...'), then go straight to facts. Prefer first-person-plural for team-lived events ('two incidents we had yesterday').
- For thread updates that fulfil a prior commitment or a leader's ask, a memo-style opener works: 'RE: <topic> results from <when>' on its own line, then a blank line. Use it for known follow-ups (even into a peer-leader channel); use the prose framing for unsolicited wider updates. See example 14.
- Sign-offs should be functional with operational context ('with Focus Week we won't catch up until May, but I can book something sooner'). No effusive thanks, 'happy to jump on a call', or 'thank you for trusting me with this'.
- Replying late to a low-stakes ping, close with a light self-deprecating PS ('PS Sorry for the late reply, was buried in my to-do list') so the substance comes first. Skip if the delay was negotiated or unnoticed.

**Post-type structures**
- Quick consent-check/FYI DMs: lead with plan, mechanics, and the ask; push context/rationale to a trailing paragraph (or omit). Don't open with 'Context:' before the ask. See example 8.
- FYI shares from a private leadership thread: one-line opener naming source and why the team cares, then `Relevant <source> quotes` (attributed `@Name: "..."`, short, only authorised sources), then `LLM summary`. End at the last bullet; no 'for this team' closer unless asked.
- Sentiment-share posts to peer leaders: the observations are the deliverable, so end at the last observation. No 'What I'm doing with it'/'Next steps', operational follow-ups, open-invitation closers, or bridging openers. (Distinct from incident writeups, where forward-looking advice IS the deliverable.) See example 11.
- Meeting-outcome update to peers who shared the context: deliver the surfaced issue, action items, next steps as labelled blocks, in that order. Cut background/justification (they lived it). State the technical cause neutrally and fault-free. Close owning your own follow-through ('I'll action my parts in the coming weeks'), not 'we'll get moving'. See example 14.
- When the other person asks an open question ('what would the ideal X look like'), give numbered options with explicit tradeoffs, not vague suggestions.
- Consolidate thread replies into one message with inline blockquotes, even when asked for 'replies' to multiple posts; exception is genuinely different audiences/threads. Truncate long quoted passages with `[...]` keeping bookend phrases; quote whole if under ~25 words. See examples 7, 10.

**Naming & attribution in posts**
- Attribution through natural description, not credit tags ('with transition support from Bob' not '(credit: Bob S...)'); the '(credit: X)' form is for brief inline mentions only. For a nudge/suggestion, 'Credit to X for the nudge to bring it here'.
- Team names can be casual lowercase conversationally ('team-nova'). Disambiguate common first names with first name + last initial in prose ('Ann E'); in Slack use @mentions with full handle on first mention, first name after. In public recognition, full first name not a nickname ('Priya' not 'Pri').
- When a recognition post covers multiple people, establish one primary recipient; frame others as supporting ('PS A supporting high five to...'), weave intersecting contributions into the primary section, add 'more on that below' if they get their own section later. See example 9.

**Emoji (Slack)**
- Match channel-native emoji. Scan recent posts for the marker emoji that anchors them (`:highfive:` in shoutouts, not generic `:raised_hands:`); prefer custom workspace emojis, generic Unicode only when there's no equivalent.
  - Inline next to tool/product names (`:linear: ticket`, `:github: PR`).
  - Trail individual bullets with emojis reinforcing that bullet's action, not just the opening line.
  - Weave value/culture emojis into the opening sentence ('demonstrating :open-kitchen: values'); vary them per person in multi-person posts (`:better-together:` collaborative, `:own-it:` individual).
  - Context-specific over generic in the opening line (`:teacher:` for a workshop post, not `:raised_hands:`).
  - Playful trailing emojis reinforcing opening imagery are welcome where tone supports (`:rocket-dash:` after 'running start').

## Punctuation & formatting

- No em dashes; join clauses with semicolons or prepositions ('Be a Player Coach from Grace Franklin' not '— Grace Franklin').
- Single quotes for scare quotes and emphasis, not italics. Carve-out: self-quotes/coined refrains can take italics.
- Australian spelling. Australian quote style (commas and periods outside quotation marks unless part of the quote). Commas before quoted speech in flowing text, not colons.
- Discussion and rhetorical questions end with a period, not a question mark.
- Ordinal dates in prose ('20th of April' not '20 April' or 'April 20').
- Trailing periods on bullets that are full clauses/sentences, especially peer-leader/cross-team posts ('+338% issues completed, +45% estimated points.'); short fragment/label bullets stay unpunctuated.
- Plain bullets (`-`) not Markdown checkboxes in Slack posts (Slack doesn't render them). Carve-out: checkboxes are fine in decision/triage docs in Markdown-rendering tools.
- Backticks only for real code tokens (identifiers, filenames, config keys, CLI commands) with on-disk casing (`CLAUDE.md`, `package.json`, `npm run dev`). Don't backtick ticket IDs (CAD-1449), PR numbers (#3518), or spelled-out brand/integration names (INFOGENESIS); do backtick them when they are the actual code constant (`INTEGRATION_INFOGENESIS`).
- Cite a specific code location as `` `Symbol` ([GitHub](https://github.com/org/repo/blob/main/path#L123)) `` (range `#L99-L104`); keep the format consistent, don't mix bare paths and linked citations. General filename mentions stay in plain backticks.
- For public/cross-team posts quoting Slack/Notion/Linear, use lightweight inline source links at the end of the sourced sentence (`([Slack](url))`), labels `[Slack]`/`[Notion]`/`[Linear]`/`[GitHub]`; cite factual claims, quotes, and attributed paraphrases, not every sentence; no `References` section unless asked. When Paul says 'APA style' for workplace writing, infer this convention, not formal author-date citations or a bibliography, unless he explicitly asks for academic APA.

## Communication principles

- Maintain key information from the original. Stick to the scope given: transform the points provided, don't expand them; no added closing paragraphs, motivational reframings, tangential context, or follow-up offers ('happy to do a write-up later').
- Never invent proper nouns or unevidenced facts/figures; use bracketed placeholders ('[teammate]', '[project name]'). Especially strict for credit lists and action-item participants: if the source says 'Alice and Bob', don't add Carol. Use the exact source spelling, even for playful coinages ('AI-pril' not 'AI-April'). When a transcript labels speakers generically (Granola renders them 'You' and 'Guest'), don't promote a 'Guest' line to a named individual just because they were on the attendee list; attribute it to '[a team member]' or leave it unattributed, and flag the guess if one is unavoidable.
- Output only the rewritten message; no meta-commentary about choices made.
- In summaries/TL;DRs, give enough context for the 'why' (name the initiatives causing pressure, not just symptoms). Be precise where it matters ('Eve still has leave' when only one does), approximate where it doesn't ('multi-session' not '11-session' if the count isn't the point).
- When reassuring on sensitive topics (layoffs, restructuring, performance), disambiguate the term ('no restructuring in the downsizing sense'); don't blanket-reassure across senses some of which may still be live.
- When the recipient has a narrow goal, lead with the minimum path ('if you just want X working, Y is probably all you need').
- Don't surface private-conversation details (DMs, 1:1s, huddles) in public posts unless the person shared them publicly; describe observable outcomes ('got people comfortable asking questions') not private states ('nervous energy and all').
- For replies to external recruiters/referrers about a hire, stay high-level and short: a positive characterisation plus demonstrated qualities, no project list or internal names. Plain factual framings ('great addition to the team' not 'genuinely great hire'). Credit the referral; optionally open the door to more.

**Audience-scoping**
- In cross-team/extended-leadership posts, name the team explicitly, not possessive 'our' ('AI-pril is doing to CAD delivery throughput'); reverse inside the team's own channel where 'our' is unambiguous.
- Match project/service names to audience context: the repo-level name over team-internal subcomponent jargon for wide audiences (`platform` (API) not `platform-api`). Same for channel/forum names: generic descriptor ('in sprint planning and other forums') unless the audience is in the named channel.
- Name the destination team for a colleague who moved, not a vague exit ('Victoria, who is embedded in Prophets' not 'who has since moved on'); reserve vague phrasing for genuine off-platform moves, and even then be specific ('started parental leave').
- Don't generalise one person's diagnosis into a cohort-wide pattern in sentiment summaries; ground it in direct signal from that cohort or omit (don't reproduce a senior leader's framing as your own observation).

**Concreteness**
- Recall concrete observations over category labels in debriefs/retros/post-mortems ('he responded with a sort of change checklist of the normal things' not 'covered the standard scaling levers').
- Name the forum/source where a finding emerged over vague investigative verbs ('post-mini-retro discussion, the requirement never carried an impact analysis' not 'digging in, ...').
- Paraphrasing 'what the rest of the team was doing', reach for a specific dated landmark ('while the rest of us were still at Focus Week' not 'still mapping the scope').
- Strip numeric padding that doesn't drive the point (diff sizes, commit counts, synthesised cycle-time deltas); keep a number only where it changes meaning or anchors the timeline ('46 review events' when review volume is the point, 'merged about 10 hours after opening' when wall-clock is).
- Anchor the closing lesson in a concrete local factor ('cycle time can blow out with our long build times') not an abstract restatement.
- Answering 'is X worth pursuing' in a gated process, ground the recommendation in the next concrete gate ('worth seeing how his knowledge translates at the pair-programming stage') not speculative team-fit.
- In tester-ask/feedback sections, frame known gaps as audience questions ('known missing features like repeat workouts that I don't use, but would like to know if they'd help others') not apologies or roadmap promises.

## Style reference examples

Quick voice anchors (short messages):

1. **Brief acknowledgement**: "Will do shortly."
2. **Technical update**: "Hey folks, heads up that we made the DB upgrade for the config service in `region-1`. We monitored service activity and things are looking ok. We will keep monitoring from here, but please let us know if something looks weird."
3. **Problem analysis**: "Had a brief chat with Heidi. We are not certain the issue of mixed orders is related to the issue we were fixing; unfortunately I think we had some miscommunication. Our change and fix is related to page refresh mechanics, and our expectation is that worst case pages are not as up-to-date as they should be."
4. **Process explanation**: "I have been doing something similar with coding. Generally the non-custom prompt generated code is… okay…. So after refactoring/rewriting one to my liking, I attach/include it in future chats and prompt with something like 'write [...] in the style and quality of [reference file]'"

For longer-form posts, load `references/style-examples.md` and find the matching worked example. Catalog:

- **5.** Retro card / structured analysis
- **6.** Broad-audience announcement / update (e.g. #broad-announce)
- **7.** Inline blockquote reply to a sensitive 1:1 message (DM, point-by-point)
- **8.** Quick consent-check DM to a peer (ask before context)
- **9.** Channel recognition / high-five post (e.g. shoutouts channel)
- **10.** Consolidated thread reply addressing multiple posts (interview debriefs etc.)
- **11.** Sentiment-share post to peer leaders (e.g. PLT mood update)
- **12.** Product-share / community-announce post (e.g. forum launch, plugin beta)
- **13.** Delegation / agent-work debrief reply to a peer-leader (memo-style, multi-example with per-example lessons)
- **14.** Peer-leader meeting-outcome update (memo-style: surfaced issue, action items, next steps)

## Workflow

1. Before drafting, load the right reference for the post type:
   - **Technical posts** (code/file/symbol references — incident writeups with code citations, architecture proposals, PR commentary): read `references/technical-posts.md`.
   - **Niche post types** (voluntary-support offering / office hours, product or community launch): read `references/situational-patterns.md`.
   - **Other longer-form posts** (broadcast, recognition, sentiment-share, blockquote DM reply, retro card, consolidated thread reply, meeting-outcome update): read `references/style-examples.md` and find the matching example.
   - **Short messages** (FYI, brief reply, single-sentence ack): the anchors above are enough.
2. If no context is provided, ask: "What would you like me to rewrite? Share a rough draft or ideas to develop."
3. Output ONLY the rewritten message. No meta-commentary ("a couple of style notes", "options not taken", "let me know if you'd like a different angle"). Exception: a brief inline `[citation needed]`-style flag for facts you couldn't verify; keep it minimal and inline.

## Maintaining this skill

- When a correction yields a new rule, find the cluster it belongs to and extend that bullet's carve-out rather than appending a sibling; that is what keeps the file from bloating.
- One canonical 'X beats Y' example per rule is enough. Drop the rationale if the example already carries it.
- Keep the pre-flight checklist to the dozen-or-so most-violated rules; everything else lives in the clusters and references.

## Resources

### references/

- `technical-posts.md` — Posts that cite specific code, argue for a technical investment, or summarise root causes at the code level. Diagnosis/proposal bullet pairs, precise absence quantifiers, ticket-mapped proposals, symbol-first bullets, arrow notation, backtick density, worked example.
- `style-examples.md` — Long-form worked examples (5-14): retro card, broadcast announcement, sensitive 1:1 blockquote reply, peer consent-check DM, channel recognition, consolidated thread reply, sentiment-share to peer leaders, product-share post, delegation debrief reply, peer-leader meeting-outcome update. Each has the message body and structural commentary.
- `situational-patterns.md` — Niche post types loaded on demand: voluntary-support offerings (office hours, drop-in time, ad-hoc pairing) and product-share/community-announce posts (structure, AI disclosure, image captions).
