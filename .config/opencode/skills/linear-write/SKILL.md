---
name: linear-write
description: "Create or rewrite Linear issues using the agent-ready card template. Use when asked to create/rewrite a Linear issue, write a spike, or clean up an issue from a URL/ID."
---

# Linear Write Skill

Create new Linear issues, or rewrite existing ones, following an agent-ready card template. The goal: produce specifications precise enough for an autonomous agent to execute on the first pass, with verifiable acceptance criteria, explicit scope, and tight risk tiering.

## Tooling: MCP first, CLI fallback

Always prefer the Linear MCP tools. Fall back to the `linear` CLI only when MCP is unavailable or the task needs something MCP cannot do.

| Action          | Preferred (MCP)                               | Fallback (CLI)                 |
| --------------- | --------------------------------------------- | ------------------------------ |
| Fetch an issue  | `mcp__claude_ai_Linear__get_issue`            | `linear issue view <ID>`       |
| Create an issue | `mcp__claude_ai_Linear__save_issue`           | `linear issue create ...`      |
| Update an issue | `mcp__claude_ai_Linear__save_issue` (with id) | `linear issue update <ID> ...` |
| List teams      | `mcp__claude_ai_Linear__list_teams`           | `linear team list`             |
| List projects   | `mcp__claude_ai_Linear__list_projects`        | `linear project list`          |
| List labels     | `mcp__claude_ai_Linear__list_issue_labels`    | (CLI: not always available)    |
| List users      | `mcp__claude_ai_Linear__list_users`           | n/a                            |

When passing markdown to MCP tools, send real newlines, not literal `\n` escape sequences.

## The Core Principle

You are writing a contract, not a conversation starter. Every ambiguity is a coin flip the agent will make without telling you. A card that is good enough for an agent is excellent for a human.

## Writing style

Rules apply to issue bodies, comments, and spikes alike:

- No em dashes; use semicolons, commas, or prepositions instead.
- Australian spelling.
- Backticks for code identifiers, filenames, config keys, and CLI commands; preserve on-disk casing (`CLAUDE.md`, `package-lock.json`, `npm typecheck`).
- Plain, concrete language over institutional terms ('the arrangement' not 'the program design').
- Don't add wrap-up, summary, or evaluative closing sentences; stop when the facts are stated.
- Single quotes for scare quotes and emphasis ('in theory'), not italics.
- Lead with the finding or action, not validation or framing.
- Cite sources APA/Harvard style: a short hyperlinked label in parentheses after the referenced statement, e.g. `data stops flowing once a site is migrated ([Playbook](https://...))`. One-word labels only; hyperlink the label, not surrounding prose. Don't drop raw URLs inline or use numbered footnotes like `[1]` (Linear escapes the brackets).

## The Agent-Ready Card Template

Every issue you create or rewrite MUST follow this structure:

````markdown
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

- The relevant entry point is most likely `ClassName.methodName` ([GitHub](https://github.com/org/repo/blob/main/src/path/file.ts#L42)), which currently does:

  ```typescript
  // 👇 reproduce the problematic block so the edit site is unambiguous
  [short snippet of the referenced code, with 👇/👈 markers on the line(s) to change]
  ```

- Alternative: follow the pattern in `OtherService.method` ([GitHub](https://github.com/org/repo/blob/main/src/other.ts#L15)), or use the existing utility at `src/utils/helper.ts`
- Constraints: [any binding context the agent must respect, e.g. 'do not introduce a new dependency', 'must run inside the existing transaction']
- When uncertain: stop and explain the ambiguity, or propose a short plan rather than guessing

## Verification

- [ ] `npm typecheck` passes with zero errors
- [ ] `npm lint` passes with zero warnings
- [ ] `npm test -- --filter=<area>` is green
- [ ] `git diff` shows changes only in `src/<scope>/` and `tests/<scope>/`

## Risk tier

[Low / Medium / High] - [One sentence justification]

## Files likely involved

- `src/[module]/[file].ts`
````

### Why each section matters

- **Acceptance criteria** must be programmatically verifiable. If "done" requires a human judgment call, the card is not agent-ready. Replace "improve error handling" with "OAuth callback handler passes the three test cases in `tests/auth/oauth_callback.test.ts`".
- **Out of scope** prevents agent wandering. Agents are eager to "improve" adjacent code. Name what must not be touched, even when it looks related.
- **Implementation guidance** is the section that most often decides whether a card runs on the first pass. See the rules below.

### Writing the implementation guidance section

Research the codebase as part of drafting; don't wait to be asked. If you have no repo access, say so in the draft and flag the section as best-effort.

**Research checklist**

- Locate the primary entry point: the file and symbol where the change most likely lands. Use `rg`/`grep`, file search, or an Explore agent for breadth.
- Read the surrounding code so the guidance reflects the pattern the agent must match or extend.
- Identify at least one alternative approach or reference pattern elsewhere in the codebase.
- Note binding constraints: transactions, feature flags, dependency boundaries, existing utilities the agent should reuse.

**Structure**

1. **Primary approach** — name the most likely entry point by symbol and file, with a GitHub deep link. Frame as the 'culprit' or 'entry point', not a prescription. Default to reproducing the referenced code as a fenced snippet whenever it helps illustrate the edit; skip only when the code is >~10 lines or purely structural.
2. **Alternatives** — patterns elsewhere in the repo the agent can mirror. Label ordered attempts as 'attempt 1', 'attempt 2'.
3. **Constraints** — binding rules the agent must respect.
4. **When uncertain** — one-line instruction to stop and surface ambiguity rather than guessing.

**Formatting rules**

- Symbol links follow APA/Harvard-style citation: `` `Class.method` ([GitHub](https://github.com/org/repo/blob/main/path/to/file.ext#L123)) ``. Symbol in backticks, then a parenthetical `[GitHub]` label hyperlinked to the exact line. Use `#L123-L145` for ranges. Don't wrap the backticked symbol inside the link text.
- Backtick all code identifiers, filenames, config keys, and CLI commands; preserve on-disk casing.
- Use fenced code blocks tagged by language (```typescript, ```python, ```sql).
- Mark edit sites inside snippets with emoji comment arrows:
  - `// 👇 ...` on the line above when the target line is long.
  - `// 👈 ...` as a trailing inline comment when the target line is short.
  - Choose one per site; don't stack both. The comment names the edit (e.g. `// 👈 missing tax recalc here`), not the code.
- One real code snippet outperforms three paragraphs of prose. If you find yourself writing a paragraph, link to an example file instead.
- The heading is `## Implementation guidance` (sentence case). Do not capitalise the `g`.

### Risk tier reference

| Tier                | Examples                                     | Review expectation          |
| ------------------- | -------------------------------------------- | --------------------------- |
| **Low**             | UI copy, config, test coverage, docs         | Auto-merge when gates pass  |
| **Medium**          | New endpoint, single-module refactor         | One human reviewer          |
| **High**            | Auth, payments, data migrations              | Two humans incl. security   |
| **Do not delegate** | Architecture, novel algorithms, PII handling | Human writes, agent assists |

### The Complexity / Ambiguity matrix

|                     | Low ambiguity                                                       | High ambiguity                                  |
| ------------------- | ------------------------------------------------------------------- | ----------------------------------------------- |
| **Low complexity**  | Automate immediately. First wins: config, copy, tests, simple CRUD. | Needs a spike first. Agent will guess wrong.    |
| **High complexity** | Good candidate if broken into sub-tasks.                            | Human-driven. Architecture, novel integrations. |

If a card lands in "high ambiguity", propose a spike instead of trying to write it as an executable card.

## Workflow

Applies to both creating and rewriting. Steps flagged **[rewrite]** only apply when rewriting an existing issue.

1. **[rewrite] Fetch and read.** Extract the Linear issue ID (`CAD-1295` or a `linear.app` URL), fetch via `mcp__claude_ai_Linear__get_issue`, and identify the core goal, listed items, open questions from the original author, and any scope/exclusion context.
2. **Clarify before drafting.** Ask the questions needed to fill every section of the template. Common gaps: team/project/labels/assignee, scope boundaries, acceptance criteria, verification commands, risk tier and justification, sub-issue grouping, and (on rewrites) answers to the original author's open questions.
3. **Research the codebase** to fill in implementation guidance. Default to doing this whenever you have repo access (current working directory, a repo the user has opened, or GitHub search); do not wait for the user to prompt you. Follow the research checklist above. If you have no repo access, state that explicitly and mark the section best-effort.
4. **Draft the full issue** using the template. Present the draft to the user and wait for approval before writing to Linear.
5. **Create or update the issue** via `mcp__claude_ai_Linear__save_issue` (pass the existing id on a rewrite) or, as fallback, `linear issue create ...` / `linear issue update <ID> ...`.
6. **Return the URL and identifier** (e.g. `CAD-1234`).
7. **Create sub-issues** if requested. Each follows the same template, references the parent, and uses the same team/project/labels.

### [rewrite] Preserving original content

When rewriting, always preserve the original description in a collapsed section at the bottom, and add a Q&A section if the original had open questions or clarifying questions were answered during the rewrite:

```markdown
+++ # Original description (pre-YYYY-MM-DD)

[original description verbatim]

+++

## Q&A

**Q (original author):** [question from original description]
**A:** [answer determined during rewrite]
```

## Spike Issues

A spike is a time-boxed investigation, used when ambiguity is too high to write an executable card. Ask how many days the spike should be.

**Title format.** Prefix the title with the duration in brackets: `[2 day spike] Title`, `[½ day spike] Title` (use the ½ character), `[1 day spike] Title`. **Always apply the `spike` label** (`-l "spike"` via CLI, or include it in the labels list via MCP).

**Description template.** Pick Spike Questions (investigating an unknown) or Action Items (enumerating known work):

```markdown
# Spike Questions to Address  ← use for exploratory spikes

- What is the size and scale of the problem?
- What is the root cause?
- What are the potential solutions or fixes?
- Is it worth fixing? (effort vs impact)

# Action Items  ← use for enumeration spikes

- Review scope and identify specific items that need work
- Note constraints or special considerations for each item
- Compile list of tasks; have team/PM review and prioritise
- Create Linear issues for approved work

# Possible Outcomes

- Additional spike required; if further investigation is needed
- Close as won't do; if effort outweighs benefit
- Create resolution issue / sub-tasks for each item; if we decide to proceed
- Fix issue; if solution is simple and time allows
```

Use bullets, not numbered lists. Linear's renderer silently drops items after the first in multi-item numbered lists saved via MCP.

## Comments

Comments follow the same writing-style rules as issue bodies. Investigation findings, audit results, and out-of-band updates belong in comments; the description is the contract, the comment is the journal.

**Investigation finding template** (for comments documenting an audit, CVE triage, 'not reproducible' outcome, etc.):

```markdown
**[One-line finding in bold.]**

[Short paragraph explaining the finding with the key file/line link.]

Verified by:

- [Specific check 1, with the exact command or URL]
- [Specific check 2]

[Optional: short paragraph on related-but-unaffected items you considered.]

[Recommendation, e.g. 'Closing as cancelled' or 'Reopening as P2'.]
```

The verification list is load-bearing. Each bullet should be a check the reader can re-run: a `git log -S` command, a clickable GitHub code search URL, a specific file path with line numbers. No vague 'I checked the codebase' prose.

## Issue Relationships

| Relationship   | MCP                                | CLI                | How to set                           |
| -------------- | ---------------------------------- | ------------------ | ------------------------------------ |
| **Parent**     | Yes (`save_issue` with `parentId`) | Yes (`-p <ISSUE>`) | Set during creation, or update later |
| **Sub-issue**  | Automatic                          | Automatic          | Create with parent set               |
| **Blocked by** | Limited                            | Not supported      | Set manually in Linear web UI        |
| **Depends on** | Limited                            | Not supported      | Set manually in Linear web UI        |

## CLI Reference (fallback)

```bash
# Install and auth (once)
npm install -g @linear/cli   # or: brew install linear
linear auth login

# Create
linear issue create --team <TEAM> -t "<TITLE>" -d "<DESCRIPTION>"

# Spike with label, long description via file (avoids shell escaping)
linear issue create --team ENG -t "[2 day spike] Investigate slow checkout" -l "spike" --description-file spike.md
```

Non-obvious flags worth knowing:

- `-p, --parent <TEAM-NUMBER>` — parent issue, e.g. `CUSM-42`.
- `-l, --label <LABEL>` — repeatable.
- `-a, --assignee <self|username>`, `--priority <1-4>` (1=urgent), `--estimate <POINTS>`.
- `--description-file <PATH>` — read description from file; bypasses shell quoting issues with `@`, backticks, newlines.
- `--no-interactive` — skip prompts for scripted use.

Run `linear issue create --help` for the full flag list.

## Tips and Gotchas

- **Escaping `@` mentions.** Linear parses `@` as a mention trigger and shells may interpret it as command substitution. Wrap package names in backticks (`` `@mr-yum/foo` ``) inside descriptions; wrap shell args in single quotes; or use `--description-file` to bypass shell quoting entirely.
- **Team identifiers** are usually uppercase (CAD, ENG, PROD, CUSM).
- **Numbered lists get truncated.** Multi-item `1.` `2.` `3.` lists saved via MCP often drop everything after the first item silently. Use bulleted lists unless order is semantically required, and verify with `get_issue` if you do use numbers.
- **More detail isn't always better.** A 500-word card with contradictory instructions is worse than a 100-word card with clear acceptance criteria.
- **Prefer linking to one example file** over writing a paragraph of prose about a pattern.

## Guidelines

- Do not create or update an issue until the user approves the draft.
- Ask clarifying questions up front rather than guessing at scope or implementation details.
- If acceptance criteria sound testable but are subjective ("clean up the error handling", "improve" something), push back and rewrite them as something verifiable.
- Risk tier should reflect the actual change, not the importance of the feature.
- When listing handlers, endpoints, or items, prefer grouping by module or domain over enumerating individually.
- If the work has high ambiguity, propose a spike instead of trying to write it as an executable card.
