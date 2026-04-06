---
name: rewriting-for-tone
description: "Rewrites drafts and ideas into polished communication in the user's voice. TRIGGER when: user asks to write, draft, rewrite, summarise, or share any non-code communication (Slack, email, update, report, retro card, FYI), or mentions 'my tone'/'my style'/'my voice', or provides raw notes to turn into a message. DO NOT TRIGGER for: commit messages, PR descriptions, or technical documentation."
---

# Rewriting for Tone & Style

Transform rough drafts and unpolished ideas into clear, professional communication.

## Writing Style

**Tone & Approach**
- Professional yet collaborative (not formal or stiff)
- Direct and clear, but not absolute — use measured hedging where appropriate ("is unlikely to be immediately observable" rather than "doesn't hold in practice")
- Medium formality (conversational but polished)
- Uses casual abbreviations naturally: AFAIK, IMO, etc. — can be parenthetical as asides (AFAIK) or inline. However, use these sparingly in broader-audience posts (e.g. #product-all announcements). They fit better in smaller-audience contexts like retro cards, leads channels, or DMs
- Do not over-abbreviate common words (e.g. write 'dependency' not 'dep', 'configuration' not 'config'). The casual abbreviation guidance applies to well-known acronyms, not shortening everyday words
- When requesting action or discussion, use personal ownership: "I would like to discuss" rather than "We need to talk about". Position as a request, not a demand
- Name the desired outcome explicitly (e.g. "to minimise stress on teams") rather than leaving it abstract ("how we pace this")
- Prefer simple, plain language over institutional-sounding terms ("the arrangement" not "the program design", "two-fold" not "two-pronged")
- Use concrete, specific verbs over vague ones (e.g. "once we've replaced TypeORM" not "once we're through TypeORM"; "to avoid duplicate effort" not "to make sure we're aligned")
- Don't add wrap-up, summary, or evaluative sentences that restate what was already said or implied. If the facts speak for themselves, stop there. This includes: tying things back to a framework or principle at the end (e.g. don't close with "That's the definition of leading by example" after describing someone leading by example), adding filler closers like "these are our main priorities" after listing the priorities, and editorialising with phrases like "which is a critical dependency" or "quality work we can be proud of" when the facts already convey the significance
- Avoid rhetorical contrast framing like "didn't just X; he Y" or "not only X, but also Y". Just state what happened in a straightforward list (e.g. "Ben organised the workshop, built the full curriculum, ran all sessions" not "Ben didn't just organise the workshop from a distance; he built the full curriculum himself"). Similarly, drop unnecessary intensifiers like "himself", "actually", "really" — let the actions carry the weight
- Name who owns what. When referencing work in progress or upcoming, attach a person to it (e.g. "Arjay is on the Allergen Gate work" not "the Allergen Gate work needs to land"). Include yourself explicitly in headcounts where relevant (e.g. "me + 4 engineers" not "5 engineers")
- Attribute group decisions to the group. If a decision was made collectively, name the stakeholders rather than taking sole credit (e.g. "we (Shawn, Tal, Kim) agreed to take Blake and Walter out" not "I've pulled Blake and Walter out")
- Add domain-specific context when a term could be ambiguous or unfamiliar. Use brief parenthetical clarifications for jargon or tools the reader may not know (e.g. "Nex (his own AI workflow optimised terminal emulator)" not just "Nex tooling"; "first exposure to custodianships" not just "first exposure")

**Structure & Format**
- Concise and analytical
- Prefer flowing prose paragraphs over bullet points — only use bullets when listing genuinely discrete items
- Logically organised with clear hierarchy
- When addressing problems in discussion contexts (retros, leads channels), pose the question to the audience rather than prescribing a solution (e.g. "Question for the group: how do we..." not "We need to do X and Y"). In broader announcements, prefer concrete next steps with a specific call to action (e.g. "I would encourage you to raise it with your manager" rather than an open-ended "I'd love to hear your thoughts")
- Technically detailed only when relevant
- Australian spelling
- Attribution through natural description rather than explicit credit tags. Prefer "with transition support from Shawn" over "(credit: Shawn K. for getting the project to this point)". The "(credit: X)" parenthetical pattern is reserved for brief inline mentions in shorter-form messages
- Team names can be written in casual lowercase when used conversationally (e.g. 'ctrl-alt-delight' not 'Ctrl-Alt-Delight')
- When disambiguating people with common first names in prose, use first name + last initial (e.g. 'Ben T' not 'Bente' or 'Ben Thompson'). In Slack messages written for a team audience, use @mentions with full names or handles (e.g. '@Shawn Khoo', '@BenAI') so the person is properly notified. Use the full @handle on first mention, then just the first name for subsequent references in the same section (e.g. "@BenAI" then "Ben")

**Punctuation & Formatting Preferences**
- Single quotes for scare quotes and emphasis ('in theory', not italics)
- Semicolons or prepositions to join related clauses rather than em dashes (e.g. "Be a Player Coach from Ben Friebe" not "Be a Player Coach — Ben Friebe")
- Commas before quoted speech in flowing text, not colons
- Discussion/rhetorical questions end with a period, not a question mark
- Australian quote style: commas and periods outside quotation marks unless part of the quoted text
- Ordinal format for dates in prose: "20th of April" not "20 April" or "April 20"

**Communication Principles**
- Clear and diplomatic
- Preserve technical accuracy
- Maintain key information from the original
- In summaries/TL;DRs, include enough context for the reader to understand the 'why' even without the full text (e.g. name the initiatives causing the pressure, not just the symptoms)
- Be precise where it matters, approximate where it doesn't. Use exact details when they change meaning (e.g. "Blake still has leave" not "both have leave" when only one does), but round off when the exact number adds nothing (e.g. "multi-session" not "11-session" if the count isn't the point)

## Style Reference Examples

Study these examples to understand the target voice:

1. **Brief acknowledgement**: "Will do shortly."

2. **Technical update**: "Hey folks, heads up that we made the DB upgrade for EU1 for Integration Config. We monitored service activity and things are looking ok. We will keep monitoring from here, but please let us know if something looks weird."

3. **Problem analysis**: "Had a brief chat with Alex. We are not certain the issue of mixed orders is related to the issue we were fixing; unfortunately I think we had some miscommunication. Our change and fix is related to page refresh mechanics, and our expectation is that worst case pages are not as up-to-date as they should be."

4. **Process explanation**: "I have been doing something similar with coding. Generally the non-custom prompt generated code is… okay…. So after refactoring/rewriting one to my liking, I attach/include it in future chats and prompt with something like 'write [...] in the style and quality of [reference file]'"

5. **Retro card / structured analysis**: "The challenge is that by immediately going to the team with 'well done on Q1, here's all these time-sensitive things for Q2', we're not setting a sustainable pace. For most teams with Q2 commitments, AFAIK they haven't been adjusted, and we're effectively fitting a quarter's worth of goals into two-thirds of the time.\n\nI understand the theoretical argument: AI-enablement 'in theory' doubles velocity, so two remaining months gives you four months of pre-AI capacity. But it's unlikely to work that way. Even if it did, the mental toll of effectively telling people 'you need to do three months of work in two months', before they've had the chance to prove that enhanced velocity for themselves, IMO leads to increased delivery anxiety.\n\nQuestion for the group: how do we set expectations and pace for teams coming off a heavy Q1 into a shortened Q2."

6. **Broad-audience announcement / update** (e.g. #product-all): "We identified that as our streams have matured, domain knowledge has increasingly concentrated within individual teams. That's somewhat expected, but it limits how quickly people can grow across domains and makes us more fragile when priorities shift. To address this, we're trialing cross-stream secondments as a way to deliberately move knowledge between streams, support individual development, and build broader platform context across the org.\n\n[...lessons learned section...]\n\nNext steps: if a secondment or cross-stream rotation is something you'd be interested in, or if there's a domain you've been wanting to build experience in, I would encourage you to raise it with your manager as part of your next career development conversation. We're interested in making this opportunity available to all engineers, and having a pool of interested people make it easier to facilitate secondments."

## Transformation Guidelines

When transforming user input:

1. Analyse the content type and purpose
2. Match the appropriate level of formality from the examples
3. Preserve all technical details and key information
4. Apply the direct, collaborative tone
5. Organise logically with clear structure
6. Avoid bolding within bullet points

## Workflow

1. If writing context is already provided, transform the writing immediately
2. Otherwise, ask: "What would you like me to rewrite? Share a rough draft or ideas to develop."
3. After producing the initial version, ask if they want specific adjustments
4. Refine based on feedback
5. Iterate until satisfied
