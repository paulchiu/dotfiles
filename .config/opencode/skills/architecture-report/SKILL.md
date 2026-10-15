---
name: architecture-report
description: "Research a codebase's current architecture into a dated HTML page plus .md: layers, flows, a dependency chart, tree measurements (deepest dirs, busiest dirs, files over 200/500 lines), longest functions and methods, verified deep call chains, hotspots, and optional ranked refactor suggestions. Use for an architecture report, dependency chart, call-chain or hotspot analysis of a repo."
---

# Architecture Report

Produce a read-only research report on how a codebase is built today. The output is a dated HTML page (readable on a phone) and a companion `.md`, both in `~/dev/sandbox` unless a location is given. Name them `yyyy-mm-dd <Repo> architecture.html` and `.md` (see `dated-doc`).

## Inputs

- **Repo path** and ref. Record `git -C <repo> log --oneline -1` and the version tag if there is one; the report pins to that SHA.
- **Sections wanted.** Default is everything in "Report structure". Call chains and refactor suggestions can be added later as updates to the same files.
- **Publish?** Publish the HTML as an Artifact only when Paul asks (for example he is reading on mobile). Republish updates to the same URL by reusing the same file path.

## Guardrails

- Read-only on the target repo: no edits, commits, branches, installs, builds or test runs that write files. Indexing with codebase-memory is fine.
- Do not commit the sandbox files unless asked. If the sandbox archive step would commit, skip it and say so.
- Nothing leaves the machine except an Artifact publish Paul asked for.

## Workflow

1. **Map the code with codebase-memory first** (see the `codebase-memory` skill). `list_projects`, then `index_repository` if the repo is missing or stale. If `nodes > 0` but `edges = 0`, reindex with force. Then `get_architecture`, `search_graph`, `query_graph` and `trace_path` for modules, classes, components and imports. Read files where the graph is thin. Read the repo's `AGENTS.md`/`CLAUDE.md` for its own layer rules and check the import graph against them.
2. **Measure the tree** with the commands in "Measurements". Say which counting method you used.
3. **Find the longest functions and methods** (see "Longest functions").
4. **Find deep call chains** (see "Call chains"). Verify every hop in the source before it goes on the page.
5. **Write the page.** Load the `artifact-design` skill first if it will be published (run Artifact `quickstart` with intent `other` when the tooling asks). Draw the dependency chart as inline SVG with no external libraries, scrollable inside its own box so the page never scrolls sideways at phone width. Write the `.md` alongside it (Obsidian-readable, no hard wraps, frontmatter with `date`, `repo`, `ref`, `rendered`).
6. **Optional: refactor suggestions** (see below), then publish or republish if asked.
7. **Report back:** the Artifact URL if published, both absolute file paths, and a five-line summary of findings.

## Report structure

Lead with a three- or four-line summary. Then:

- **Architecture:** entry points, layers or tiers with file and line counts, the composition root, and whether imports obey the repo's layer rules (count internal imports, type-only imports and cycles; say whether each cycle exists at runtime).
- **Main flows:** read, write and any undo/sync path as arrow chains of real function names.
- **State and persistence:** what is stored where, what is derived and never stored, what lives only in memory.
- **Dependency chart:** every import between source files, grouped by layer.
- **Deep call chains:** table plus hop lists (see below).
- **Measurements:** the three tables.
- **Longest functions and methods:** table plus notes (see below).
- **Hotspots and observations:** tie the big files and dense directories back to the architecture. Note test coverage by layer, files whose line count hides their size (inline SVG or data), and any false graph edges you found.

## Measurements

Uses `git ls-files` so `.gitignore`d build output is excluded; lockfiles are dropped. Use plain `awk`, `grep` and `find`, not the `ls`/`du` aliases. Set `S` to the scratchpad.

```bash
git -C "$REPO" ls-files -co --exclude-standard \
  | grep -vE '(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|bun\.lockb?|Cargo\.lock|poetry\.lock|uv\.lock|go\.sum|Gemfile\.lock)$' > "$S/files.txt"

# Deepest directories: depth, path
awk -F/ 'NF>1{d=""; for(i=1;i<NF;i++){d=d (i>1?"/":"") $i; print i"\t"d}}' "$S/files.txt" | sort -u | sort -k1,1nr -k2 | head -10

# Most files: direct, recursive, path
awk -F/ '{dir="."; if(NF>1){dir=$1; for(i=2;i<NF;i++) dir=dir"/"$i}; direct[dir]++; rec["."]++; p=""; for(i=1;i<NF;i++){p=p (i>1?"/":"") $i; rec[p]++}} END{for(d in rec) printf "%d\t%d\t%s\n", direct[d]+0, rec[d], d}' "$S/files.txt" | sort -k1,1nr -k2,2nr | head -10

# Files over 200 non-blank lines (comments counted); report 500+ as its own tier
while IFS= read -r f; do [ -f "$REPO/$f" ] && grep -Iq . "$REPO/$f" && printf '%d\t%s\n' "$(grep -cv '^[[:space:]]*$' "$REPO/$f")" "$f"; done < "$S/files.txt" | awk -F'\t' '$1>200' | sort -k1,1nr
```

Mention the next one or two files under 200 so the reader sees the cliff.

## Longest functions

Pull spans and complexity from codebase-memory, then sort yourself. Its Cypher returns plain properties but does not evaluate arithmetic, `ORDER BY` on an expression or a computed alias, and line numbers come back as strings:

```
MATCH (f) WHERE f:Function OR f:Method
RETURN f.qualified_name, f.file_path, f.start_line, f.end_line, f.cognitive, f.complexity
```

On a large repo, add `AND f.file_path IN [...]` with the files from the 200+ line list instead of pulling every node. Compute `lines = end_line - start_line + 1`, sort descending, and check the top entries in the source (spans can be off where a declaration has decorators or JSDoc above it).

On the page, split source from tests and show the top 10 to 15 source functions over 50 lines, flagging 100+: `file:name`, lines, cognitive and cyclomatic complexity, whether it has a test, and the call chains it sits on. Then notes:

- **Containers:** a factory, closure or class body's span includes its inner functions (for example a `createX()` returning an object of closures). Mark these and give the largest inner function instead of counting them as one long function.
- **Inline callbacks:** long arrow functions passed to a framework (event handlers, `onChange`, lifecycle registrations) are often not graph nodes. Their lines count toward the enclosing function, so say when a long entry point is mostly registrations.
- **Length versus complexity:** a long function with low cognitive complexity (straight-line DOM building, menu lists) is a different smell from a short one with high complexity. Call out both.
- Name the test file that covers each long function, or say it has none.

## Call chains

Depth is the number of calls from the trigger (an event handler, command, route, job or callback the framework invokes) to the deepest frame.

1. Start from entry points: app or plugin startup, commands, routes, view and event handlers, background jobs, settings.
2. Get candidates from codebase-memory: variable-length `CALLS` paths in `query_graph` and `trace_path(mode="calls")`.
3. **Do not trust the graph's chains.** It resolves built-in method names (`Array.find`, `Map.get`, `Promise.all`) to same-named project methods, and it misses calls through context objects, callbacks, listeners and interfaces. Drop every cross-file edge with no matching import, then open each remaining hop in the source. Add chains the graph missed.
4. Mark hops through a callback, listener or interface with `⇢`: static analysis cannot follow them, so they are where untested behaviour hides.

On the page: a table of the top 5 to 8 chains (trigger, depth, layers crossed, verdict `fine` or `watch`), a hop list per chain as `file:function`, and the deepest one or two drawn as a vertical step list. Then takeaways: shared tails (and whether they are pure and tested), the `⇢` hops and their test coverage, and how far the raw graph was off.

## Refactor suggestions (optional)

When asked how to refactor the deep chains or hotspots, delegate to a Fable subagent (Agent tool, `model: "fable"`, read-only) with the report path, the repo path and the chain summary. Ask it to:

- verify the report against the source and list extra facts it finds;
- separate **depth that is fine and should stay** (pure, tested tails; deliberate seams such as a single write path or a listener that keeps a lower layer from importing a higher one) from **depth worth cutting** (usually at the top of the chain: redundant recomputation, over-eager saves or rescans, untested indirections);
- for each suggestion give the chains it affects, files and functions, a short before/after sketch, the effect on depth, testability and performance, effort (S/M/L) and risk;
- respect Paul's preferences (small surface area, FP style, self-documenting code, high unit coverage) and the repo's layer rules;
- rank them and name the two or three to do now, plus what waits for the next time a file is opened.

Relay the result. If Paul agrees, package it as a dated plan doc (`yyyy-mm-dd <Repo> <topic> refactor plan.md`: findings, keep-as-is list, ranked suggestions, sequencing) and hand that path to the repo's implementing agent. Ask it to verify against current main and reply with a PR plan before writing code.
