# Claude Code Instructions

- No em dashes. Use commas, parentheses, colons, or separate sentences.
- JS/TS: prefer JSDoc block comments (`/** ... */`) over stacked `//` lines.
- Keep code comments concise. Explain what isn't obvious from the code; don't restate it or justify every choice. Prefer one tight sentence over a defensive paragraph. A comment covers the local concern of the line in front of it, not the whole feature. Keep the "why" in one place (usually a well-named function's JSDoc); call sites and sibling comments reference it, they don't restate it. Don't re-derive what a self-documenting call already says (`if (isAlreadyCompletedTransitionError(error))` needs no comment on how the check works). Cut any comment that re-explains context lifted from elsewhere (the "pasted-clause smell"). Never write long-winded comments: one sentence stating the contract, plus at most one short "why". Anything longer belongs in a design doc. Describe what the code does, not what it used to do.
- In OOP/MVC-style codebases, prefer slim controllers and fat service classes. A controller handles the transport concern only: decode the request, run the identity/auth checks that need the framework context, call one service method, map the result to the response shape. Everything else (loading entities, feature gates, business rules, persistence, metrics) belongs in a service, with its own module and its own spec. When a handler starts growing branches, extract rather than let it accumulate, and follow whatever service shape the codebase already uses.
- Don't put issue/ticket references (`RR-82`, `PAY-3452`, etc.) in code comments or test descriptions. Keep the explanatory text, drop the ref (the branch, commit, and PR already carry it). Exception: `TODO`/`FIXME` comments may cite an issue ref, since they're temporary follow-up markers meant to be picked up later.
- When saving a draft/note/write-up, name it `yyyy-mm-dd Title.md` (or `.html` for a rendered page; preserve acronym casing). If today's date isn't in context, run `date +%Y-%m-%d`. Save to `~/dev/sandbox` unless a location is specified.
- After saving such a file, print its absolute path in your reply. Previews and click-to-open only render on full paths.

## Key Locations

Both archives below have two layers: a summary layer and a verbatim layer. **Always search the summary layer first.** Only fall back to verbatim or raw capture when the summaries don't yield what's needed; every summary's frontmatter points at the transcript it came from.

### Meeting notes (Granola)

- Summaries: `~/granola/yyyy-mm/yyyy-mm-dd Title.md` (AI notes; frontmatter carries `attendees`, `web_url`, and a `transcript:` pointer)
- Verbatim: `~/granola/Transcripts/yyyy-mm/yyyy-mm-dd Title (transcript).md`
- `~/granola` is a symlink into the Obsidian vault on Google Drive. Pre-2025 notes sit in bare `2024/` and `2025/` buckets.

### Sandbox (drafts, write-ups, conversation archive)

- `~/dev/sandbox` is the default save location for drafts, notes, and write-ups.
- Summaries: `~/dev/sandbox/archive/yyyy-mm/yyyy-mm-dd/yyyy-mm-dd Title.md` (session index docs; frontmatter lists the source `transcripts:`)
- Verbatim: `~/dev/sandbox/transcripts/yyyy-mm/yyyy-mm-dd/{claude,opencode}-HHMM-<id>.md`
- Raw capture: `~/dev/sandbox/.conversation-capture/` (JSONL, last resort only)
- `~/dev/sandbox/outputs/` is local working space for non-renderable files, not documentation.

### Skills

- `~/.config/opencode/skills`, with `~/.claude/skills` symlinked to it. Tracked by yadm from `~`, so it is not its own git repo.

## Shell / CLI Aliases

My interactive shell (`~/.aliases`) redirects several common commands to modern replacements, and the Bash tool inherits them. Do NOT pass the old tool's flags to these; call the replacement with ITS own syntax.

- `du` → `dust`, `df` → `duf` (different output/flags; don't pass classic `du`/`df` flags).
- `ls`/`l`/`la`/`ll` → `eza` (use eza flags, e.g. `--icons -l -a`).
- `grep` → `grep --color=auto …` and `diff` → `diff --color`: same underlying tools, all normal options work.
- If you genuinely need the original binary, bypass the alias with `command <tool>` or the full path.

## Response Style

- When asked for a diagnosis, review, or analysis: provide the answer FIRST in 1-3 sentences, then offer to investigate deeper if needed. Do not run extensive bash exploration before stating a hypothesis.
- When given a specific subject (a person, ticket, or file), scope work narrowly to that subject. Do not expand to "review all related items" unless explicitly asked.

## Linear Conventions

- Linear collapsible syntax uses `+++ Title` / `+++` markers, NOT GitHub-style `<details>/<summary>` tags. Always use Linear's native syntax when posting to Linear.

## PR Workflow

- When updating PR descriptions via the gh-pr skill, NEVER remove the template checkboxes. Edit content around them, not the structure.

@RTK.md
