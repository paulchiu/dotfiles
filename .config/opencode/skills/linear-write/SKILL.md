---
name: linear-write
description: Create or rewrite Linear issues following the agent-ready card template. Use when asked to create a Linear issue, rewrite/restructure an existing Linear issue, write a spike, or improve a Linear issue description. Triggers on phrases like "create a Linear issue", "write a card", "make a spike", or when a Linear issue URL/ID is provided with intent to clean it up.
---

# Linear Write Skill

Create new Linear issues, or rewrite existing ones, following an agent-ready card template. The goal: produce specifications precise enough for an autonomous agent to execute on the first pass, with verifiable acceptance criteria, explicit scope, and tight risk tiering.

## Tooling: MCP first, CLI fallback

Always prefer the Linear MCP tools when available. Fall back to the `linear` CLI only when MCP is unavailable or the task needs something MCP cannot do.

| Action | Preferred (MCP) | Fallback (CLI) |
|--------|-----------------|----------------|
| Fetch an issue | `mcp__claude_ai_Linear__get_issue` | `linear issue view <ID>` |
| Create an issue | `mcp__claude_ai_Linear__save_issue` | `linear issue create ...` |
| Update an issue | `mcp__claude_ai_Linear__save_issue` (with id) | `linear issue update <ID> ...` |
| List teams | `mcp__claude_ai_Linear__list_teams` | `linear team list` |
| List projects | `mcp__claude_ai_Linear__list_projects` | `linear project list` |
| List labels | `mcp__claude_ai_Linear__list_issue_labels` | (CLI: not always available) |
| List users | `mcp__claude_ai_Linear__list_users` | n/a |

When passing markdown to MCP tools, send real newlines, not literal `\n` escape sequences.

## The Core Principle

You are writing a contract, not a conversation starter. Every ambiguity is a coin flip the agent will make without telling you. A card that is good enough for an agent is excellent for a human.

## Writing style

Linear text is read by both agents and humans. These rules apply to issue bodies, comments, and spikes alike:

- No em dashes; use semicolons, commas, or prepositions instead
- Australian spelling
- Backticks for code identifiers, filenames, config keys, and CLI commands; preserve on-disk casing (`CLAUDE.md` not `claude.md`, `package-lock.json`, `pnpm typecheck`)
- Plain, concrete language over institutional terms ('the arrangement' not 'the program design'; "once we've replaced TypeORM" not "once we're through TypeORM")
- Don't add wrap-up, summary, or evaluative closing sentences; stop when the facts are stated
- Single quotes for scare quotes and emphasis ('in theory'), not italics
- Lead with the finding or action, not validation or framing
- Cite sources APA/Harvard style: a short hyperlinked label in parentheses after the referenced statement, e.g. `data stops flowing once a site is migrated ([Playbook](https://...))`. Use one-word labels (`(Playbook)`, `(Slack)`, `(Dashboard)`, `(Grafana docs)`); hyperlink only the label, not surrounding prose. Do not drop raw URLs inline, wrap long phrases in links (which swallow the prose), or use numbered footnotes like `[1]` (Linear escapes the brackets). Skip a `## References` section unless a source is cited many times and needs disambiguation.

## The Agent-Ready Card Template

Every issue you create or rewrite MUST follow this structure:

```markdown
## Summary
[One sentence: what this card accomplishes and why]

## Acceptance criteria
- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]

## Scope

### In scope
- [Specific change 1]

### Out of scope
- [Thing that might look related but must not be touched]

## Implementation guidance
- The relevant entry point is most likely [`ClassName.methodName`](https://github.com/org/repo/blob/main/src/path/file.ts#L42)
- Alternative: follow the pattern in [`OtherService.method`](https://github.com/org/repo/blob/main/src/other.ts#L15), or use the existing utility at `src/utils/helper.ts`
- Constraints: [any binding context the agent must respect, e.g. 'do not introduce a new dependency', 'must run inside the existing transaction']
- When uncertain: stop and explain the ambiguity, or propose a short plan rather than guessing

## Verification
[Exact commands the agent should run, e.g.]
- [ ] `pnpm typecheck` passes with zero errors
- [ ] `pnpm lint` passes with zero warnings
- [ ] `pnpm test -- --filter=<area>` is green
- [ ] `git diff` shows changes only in `src/<scope>/` and `tests/<scope>/`

## Risk tier
[Low / Medium / High] - [One sentence justification]

## Files likely involved
- `src/[module]/[file].ts`
```

### Why each section matters

- **Acceptance criteria** must be programmatically verifiable. If "done" requires a human judgment call, the card is not agent-ready. Replace prose like "improve error handling" with "OAuth callback handler passes the three test cases in `tests/auth/oauth_callback.test.ts`".
- **Out of scope** prevents agent wandering. Agents are eager to "improve" adjacent code. Name what must not be touched, even when it looks related.
- **Implementation guidance** should link to a specific file showing the desired pattern. One real code snippet outperforms three paragraphs of prose. If you find yourself writing a paragraph, link to an example file instead. Use GitHub deep links with line numbers in the form `[ClassName.methodName](https://github.com/org/repo/blob/main/src/file.ts#L42)`, backtick code identifiers, and order the section as primary approach, then alternatives, then constraints. Show problematic patterns with fenced code blocks tagged by language.
- **Verification** is the contract. The `git diff` scope check is one of the most effective guardrails: it catches wandering that tests alone would miss.
- **Risk tier** sets review expectations. After tuning, 60-70% of cards typically fall in Low.

### Risk tier reference

| Tier | Examples | Review expectation |
|------|----------|--------------------|
| **Low** | UI copy, config, test coverage, docs | Auto-merge when gates pass |
| **Medium** | New endpoint, single-module refactor | One human reviewer |
| **High** | Auth, payments, data migrations | Two humans incl. security |
| **Do not delegate** | Architecture, novel algorithms, PII handling | Human writes, agent assists |

### The Complexity / Ambiguity matrix

|  | Low ambiguity | High ambiguity |
|--|---------------|----------------|
| **Low complexity** | Automate immediately. First wins: config, copy, tests, simple CRUD. | Needs a spike first. Agent will guess wrong. |
| **High complexity** | Good candidate if broken into sub-tasks. A well-defined migration across 40 files is ideal agent work. | Human-driven. Architecture, novel integrations. |

If a card lands in the "high ambiguity" column, propose a spike instead of trying to write it as an executable card.

## Workflow: Creating a new issue

1. **Clarify before drafting.** Ask the user the questions you need answered to fill every section of the template. Common gaps:
   - Team, project, labels, assignee
   - Scope boundaries (in scope vs out of scope)
   - Acceptance criteria (what does "done" actually mean?)
   - Verification commands (which scripts run, which paths must change?)
   - Risk tier and justification
   - Sub-issue grouping if multiple deliverables
2. **Research the codebase** if the user points you at one, to fill in implementation guidance, file paths, and existing patterns.
3. **Draft the full issue** in the template above. Present the draft to the user and wait for approval before creating anything in Linear.
4. **Create the issue.**
   - **Preferred:** call `mcp__claude_ai_Linear__save_issue` with team, title, description (real newlines), and any labels/project/assignee.
   - **Fallback:** run `linear issue create --team <TEAM> -t "<TITLE>" -d "<DESCRIPTION>"` with appropriate flags.
5. **Return the issue URL** to the user, plus the identifier (e.g., `CAD-1234`).
6. **Create sub-issues** if requested. Each sub-issue follows the same template, references the parent, and uses the same team/project/labels.

## Workflow: Rewriting an existing issue

1. **Parse input.** Extract the Linear issue ID from the user's message (e.g., `CAD-1295` or a `linear.app` URL).
2. **Fetch the issue** via `mcp__claude_ai_Linear__get_issue` (preferred) or `linear issue view <ID>`.
3. **Read the current description** carefully. Identify:
   - Core goal / problem statement
   - Listed items, handlers, endpoints, resources
   - Open questions from the original author
   - Context about scope or exclusions
4. **Ask clarifying questions** before rewriting. Good questions cover:
   - Scope boundaries (in vs out)
   - Implementation details the template requires but the original lacks
   - Answers to the original author's open questions
   - Whether sub-issues should be created and how to group them
   - Verification approach
   - Risk tier
5. **Research the codebase** if the user points you at one, to fill in file paths, patterns, and verification commands.
6. **Draft the rewrite** using the template. Present the plan to the user before updating anything.
7. **Update the issue** via `mcp__claude_ai_Linear__save_issue` (with the existing id) or `linear issue update <ID> ...`.
8. **Create sub-issues** if requested.

### Preserving original content

When rewriting an existing issue:

- **Always** preserve the original description in a collapsed section at the bottom using Linear's `+++` syntax:

```markdown
+++ # Original description (pre-YYYY-MM-DD)

[original description verbatim]

+++
```

- **Always** add a Q&A section if the original had open questions, or if clarifying questions were answered during the rewrite:

```markdown
## Q&A

**Q (original author):** [question from original description]
**A:** [answer determined during rewrite]
```

## Spike Issues

A spike is a time-boxed investigation, used when ambiguity is too high to write an executable card. When the user asks to create a spike, first ask how many days the spike should be.

### Title format

Prefix the title with the duration in brackets:

- Whole days: `[2 day spike] Title of the spike`
- Half day (use the ½ character): `[½ day spike] Title of the spike`
- Single day: `[1 day spike] Title of the spike`

**Always apply the `spike` label** (`-l "spike"` via CLI, or include in the labels list via MCP).

### Exploratory spike description

Use this structure when the spike is investigating an unknown problem:

```markdown
# Spike Questions to Address
- What is the size and scale of the problem? (How many users/records are affected?)
- What is the root cause?
- What are the potential solutions or fixes?
- Is it worth fixing? (Consider effort vs impact)

# Possible Outcomes
- Additional spike required; if further investigation is needed
- Close as won't do; if effort outweighs benefit or issue is not actionable
- Create resolution issue; if we decide to proceed with a fix
- Fix issue; if solution is simple and time allows
```

Use bullets, not a numbered list. Linear's renderer truncates multi-item numbered lists in saved descriptions (items after the first silently disappear); bullets are safe.

### Enumeration spike description

Use this structure when the spike is enumerating a known list of work items:

```markdown
# Action Items
- Review scope and identify specific items that need work
- Note any constraints or special considerations for each item
- Compile list of tasks needed and have team/PM review and prioritise
- Create Linear issues for approved work

# Possible Outcomes
- Additional spike required; if scope is unclear or further investigation needed
- Create (sub)tasks for each item of work; descope certain items if effort outweighs value
```

Use bullets, not a numbered list (see the note under the exploratory template).

## Comments

Linear comments follow the same writing-style rules as issue bodies. Investigation findings, audit results, and out-of-band updates belong in comments rather than the description; the description is the contract, the comment is the journal.

### Investigation finding template

Use this when a comment is documenting the result of an investigation (e.g. 'this CVE does not apply', 'this bug is not reproducible', 'this dependency is unused'):

```markdown
**[One-line finding in bold.]**

[Short paragraph explaining the finding with the key file/line link.]

Verified by:

* [Specific check 1, with the exact command or URL]
* [Specific check 2]
* [Specific check 3]

[Optional: short paragraph noting related-but-unaffected items, so the reader knows you considered them.]

[Recommendation, e.g. 'Closing as cancelled' or 'Reopening as P2'.]
```

The verification list is the load-bearing part. Each bullet should be a check the reader can re-run themselves: a `git log -S` command, a GitHub code search URL with the raw query embedded so it is clickable, a specific file path with line numbers. Avoid vague prose like 'I checked the codebase'; show the command or link instead.

## Issue Relationships

Linear distinguishes parent/sub-issue from blocked-by/depends-on relationships. Tool support varies:

| Relationship | MCP | CLI | How to set |
|--------------|-----|-----|------------|
| **Parent** | Yes (`save_issue` with `parentId`) | Yes (`-p <ISSUE>`) | Set during creation, or update later |
| **Sub-issue** | Automatic | Automatic | Create with parent set |
| **Blocked by** | Limited | Not supported | Use Linear web UI or API, or note as a reference link |
| **Depends on** | Limited | Not supported | Use Linear web UI or API, or note as a reference link |

For relationships the tooling cannot set, instruct the user to set them manually in Linear's web interface, or include them as reference links in the description.

## CLI Reference (fallback)

### Prerequisites

```bash
npm install -g @linear/cli   # or: brew install linear
linear auth login
```

### Basic creation command

```bash
linear issue create --team <TEAM> -t "<TITLE>" -d "<DESCRIPTION>"
```

### Available flags

| Flag | Description |
|------|-------------|
| `--team <TEAM>` | Target team (e.g., CAD, ENG, PROD) |
| `-t, --title <TITLE>` | Issue title (required) |
| `-d, --description <DESCRIPTION>` | Issue description (supports markdown) |
| `-p, --parent <ISSUE>` | Parent issue as `TEAM-NUMBER` (e.g., CUSM-42) |
| `-a, --assignee <ASSIGNEE>` | Assign to `self` or username/name |
| `--priority <1-4>` | Priority (1=urgent, 4=low) |
| `--estimate <POINTS>` | Story points estimate |
| `-l, --label <LABEL>` | Add labels (can repeat) |
| `--project <PROJECT>` | Associate with project |
| `-s, --state <STATE>` | Workflow state |
| `--due-date <DATE>` | Due date |
| `--start` | Start the issue immediately |
| `--no-interactive` | Skip interactive prompts |
| `--description-file <PATH>` | Read description from a file (avoids shell escaping issues) |

### CLI examples

Basic:

```bash
linear issue create --team CAD -t "Fix login bug" -d "Users cannot login with SSO"
```

With assignee and priority:

```bash
linear issue create --team ENG -t "Update dependencies" -d "Security patches needed" -a self --priority 2
```

Sub-issue with parent:

```bash
linear issue create --team CUSM -t "Fix SMS bug" -d "Bug details here" -p CUSM-42
```

Spike with label:

```bash
linear issue create --team ENG -t "[2 day spike] Investigate slow checkout" -l "spike" --description-file spike.md
```

## Tips and Gotchas

- **Escaping `@` mentions.** Linear parses `@` as a mention trigger and shells may interpret it as command substitution. When writing package names like `@mr-yum/foo`:
  - In titles/descriptions: wrap in backticks (`` `@mr-yum/foo` ``).
  - In shell commands: wrap the entire argument in single quotes (e.g., `-t 'Update @mr-yum/sms'`).
  - Or use `--description-file` to read description from a file and bypass shell quoting entirely.
- **Team identifiers** are usually uppercase (CAD, ENG, PROD, CUSM, etc.).
- **Descriptions** support full markdown including tables, code fences, checklists, and Linear's `+++` collapsibles.
- **Update later** with `mcp__claude_ai_Linear__save_issue` (passing the existing id) or `linear issue update <ID> ...`.
- **Prefer linking to one example file** over writing a paragraph of prose about a pattern.
- **More detail is not always better.** A 500-word card with contradictory instructions is worse than a 100-word card with clear acceptance criteria.
- **Numbered lists get truncated.** When Linear saves a description through MCP, multi-item numbered lists (`1.` `2.` `3.`) are sometimes reduced to just the first item; the others silently disappear. Use bulleted lists (`-` or `*`) for anything that doesn't need ordering. Only use a numbered list when order is semantically required, and verify the saved result with `get_issue` if you do.

## Guidelines

- Do not create or update an issue until the user approves the draft.
- Ask clarifying questions up front rather than guessing at scope or implementation details.
- If acceptance criteria sound testable but are subjective ("clean up the error handling", "improve" something), push back and rewrite them as something verifiable.
- Risk tier should reflect the actual change, not the importance of the feature.
- When listing handlers, endpoints, or items, prefer grouping by module or domain over enumerating individually.
- If the work has high ambiguity, propose a spike instead of trying to write it as an executable card.
