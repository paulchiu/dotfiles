---
name: tuicr
description: "Open a pull request (pr) or a local branch diff in the tuicr review TUI"
---

# tuicr

tuicr ("tweaker") is a terminal code-review TUI with vim keybindings. It renders a GitHub-style continuous diff, takes PR-style comments at line/range/file/review level, and exports to the clipboard, stdout, or a real forge review.

Two interfaces, and they are not interchangeable:

- **The TUI** (`tuicr`, `tuicr pr`) is where a **human** reviews. It requires a TTY.
- **`tuicr review`** (`list` / `comments` / `add` / `delete` / `clearc` / `clear`) is the **agent** interface. It is non-interactive, prints JSON, and is the only part you can drive directly.

Verified against tuicr **0.27.0**, installed from **homebrew-core** (`brew install tuicr`).

Source of truth for CLI syntax is the installed binary, not this skill. Everything below was checked against `--help` on 0.27.0 and against the tagged source; the config key count moved 33 -> 38 since 0.24.0 and three claims in the previous revision of this skill are now wrong (see [What changed since 0.24.0](#what-changed-since-0240)).

> The `agavra/tap` formula is stale and was superseded when tuicr landed in core. If `tuicr --version` reports 0.19.x, the old tap is shadowing core: `brew uninstall agavra/tap/tuicr && brew install tuicr && brew untap agavra/tap`. Upgrades are `brew upgrade tuicr`; `tuicr update` (and `:update`) also exist but let Homebrew own the binary.

---

## What changed since 0.24.0

Three things the previous revision asserted are no longer true. Do not repeat them:

1. **`## Session: <slug>` is now configurable.** `[export] session_header = false` drops it (`src/output/markdown.rs:271`). The old "it cannot be done, offer the manual delete" advice is obsolete.
2. **`:comments hide` has a config key.** `pr_comments_visibility = "unresolved" | "all" | "hide"` sets the initial value, so it is no longer per-PR typing.
3. **`--type` is no longer silently unvalidated.** An id absent from a configured `comment_types` now warns on stderr. It is still stored verbatim, so a typo still lands as a custom type.

Still true and worth keeping: the export always carries unresolved remote review threads (the filter is hardcoded at `src/output/markdown.rs:470`), and only the first startup warning is ever shown (`startup_warnings.first()` in `src/main.rs:403`).

New since 0.24.0: `--remote` on the CLI, `:theme` and `:sessions`/`:reviews` ex-commands, a comment navigator panel, bare `q` no longer quitting, the `editor` config key, `ignore_whitespace = "auto"`, and `tuicr review delete` / `clearc` / `clear`.

---

## Task A: "open PR in tui"

The default reading of "open a PR in tui" is: open the PR for the **current branch**, in a new pane, for Paul to drive.

### Step 1: Establish the repo

Run `git rev-parse --show-toplevel`. If it fails, ask which repo to use and stop.

Paul works in **git worktrees almost exclusively**, so the toplevel is usually a worktree, not the primary clone. That matters for the `e` key; see [The `e` key and PR snapshots](#the-e-key-and-pr-snapshots).

### Step 2: Resolve the PR number

Only skip this if the user already gave a PR number or URL.

```bash
gh pr view --json number,title,state,isDraft,url --jq '"\(.number)\t\(.state)\t\(.title)"'
```

- **Succeeds** -> use that number. It also resolves merged and closed PRs; if `state` is not `OPEN`, say so before opening.
- **Fails** (exit 1, `no pull requests found for branch "..."`) -> the branch has no PR. Either offer Task A2 (local review against main, no PR needed) or list candidates:
  ```bash
  gh pr list --author @me --state open --json number,title,headRefName,updatedAt --limit 10
  ```
- PRs awaiting his review:
  ```bash
  gh pr list --search "review-requested:@me state:open" --json number,title,url,headRefName --limit 10
  ```
- Cross-repo (works from anywhere, note the `=` form of the flags):
  ```bash
  gh search prs --review-requested=@me --state=open --json number,repository,title --limit 10
  ```

### Step 3: Build the target string

```bash
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
```

Use `"${repo}#${num}"` rather than the bare number. The bare form needs a local forge remote and breaks outside a checkout; the qualified form always works.

**Always single-quote the target.** `#` starts a comment in zsh and bash.

### Step 4: Launch it in a pane

`tuicr pr` **cannot run headless**. Without a TTY it fetches everything, prints its `tuicr-session:` line, then dies with `Error: Device not configured (os error 6)`. `--stdout` does not change this (it moves the TUI to `/dev/tty` and frees stdout, so it still needs a terminal). Never run the TUI as a plain Bash tool call.

**If `$HERDR_PANE_ID` is set** (Paul's normal environment), split the current pane and run the command there. Parse the pane ID out of the JSON response rather than predicting it, and stay in the current tab:

```bash
pane=$(herdr pane split --current --direction right --cwd "$(git rev-parse --show-toplevel)" --focus \
        | jq -r '.result.pane.pane_id')
herdr pane run "$pane" "tuicr pr 'owner/repo#123'"
```

`--focus` is deliberate here and overrides the usual background-work default: this is an interactive TUI Paul is about to drive, not a watcher. Splits do not inherit cwd, hence the explicit `--cwd`.

`herdr pane run` types into an interactive zsh, so `~/.zshrc` has been sourced and `$EDITOR` is `nvim` inside the pane. A launch path that is **not** an interactive shell (a herdr keybinding, launchd, `sh -c`) has no `$EDITOR`, because it is exported from `~/.zshrc` and not `~/.zshenv`; tuicr then falls back to `vi`, which reads the plugin-free `~/.vimrc`. Set the `editor` config key if that ever becomes a real launch path.

Then tell Paul the pane is open and which PR it holds. Do not try to read or drive the TUI afterwards, and do not close the pane; it is his to operate.

**If `$HERDR_PANE_ID` is not set**, do not attempt a PTY workaround. Print the command and tell him to run it himself with the `!` prefix:

```
! tuicr pr 'owner/repo#123'
```

### Step 5: Report

State the PR number, title, and where it opened. If you will follow up with `tuicr review` calls, capture the session slug per Task B.

---

## Task A2: review local changes with no PR

This is Paul's agent-review loop: an agent makes changes, he reviews them against `main` before any PR exists. Same TUI, no `gh` involved.

```bash
tuicr -r main..HEAD          # committed branch work vs main
tuicr -r main..HEAD -w       # branch commits plus uncommitted changes
tuicr -w                     # uncommitted only (skips the commit selector)
tuicr -r main..HEAD -p src/  # scope to a path
tuicr -A                     # every tracked file (pristine mode, no VCS diff)
tuicr --file <path>          # annotate a file or directory with no VCS at all
```

Use `origin/main..HEAD` when local `main` is stale. Launch rules from Task A Step 4 apply unchanged.

Differences from PR mode:

- `:submit` has nothing to submit to. Export with `y` / `:clip`, or launch with `--stdout` and press `y`.
- `ignore_whitespace` applies (it is a no-op on PR diffs).
- The session slug is a local one, not `gh:...`. See Task B.
- `diff_watch_interval_ms` is worth knowing here: non-zero makes the diff re-read uncommitted changes without `:e`, so his view updates while an agent is still editing.
- **`e` always opens the real worktree file** (`src/app/reviewed.rs:203` joins the repo root unconditionally), so Neovim gets LSP, gitsigns and a writable buffer. Local mode has none of PR mode's snapshot problem.

---

## The `e` key and PR snapshots

`e` opens the file at the cursor's line in the `editor` config key, else `$EDITOR`, else `vi`. In **local** mode that is always the worktree file. In **PR** mode it is the revision under review, which is not always a file in the checkout.

From `src/app/reviewed.rs`, the worktree copy is used only when its bytes already equal the reviewed content:

```rust
if let Some(path) = worktree
    && std::fs::read_to_string(&path).is_ok_and(|on_disk| on_disk == content)
{
    return Ok(EditorTarget { path, ... });   // the real file, editable
}
// otherwise: read-only snapshot under $TMPDIR/tuicr/snapshots/<repo>-pr<N>-<sha7>/
```

So reviewing a PR from a checkout that does not hold its head gives you a **read-only copy in the temp dir, outside the repo**, mode `444`. The status bar says which one you got: `Opened src/main.rs @ 1a2b3c4 (read-only PR copy)`.

**Why it looks like Neovim lost its plugins.** It did not. Opening a snapshot with Paul's config gives 15 plugins registered, dracula applied and treesitter working, but:

- **gitsigns does not attach**, because the temp dir is not a git repo. No blame, no gutter, no `]c`.
- **the language server cannot resolve anything.** vtsls attaches but finds no `tsconfig.json` and no `node_modules`, so a TypeScript file reports dozens of bogus `Cannot find module '@common/...'` diagnostics and `gd` goes nowhere.
- **telescope and neo-tree root at the temp dir**, not the repo.
- **the buffer cannot be saved**, since the file is read-only on purpose.

**The fix, for a worktree workflow.** Launch tuicr from the worktree that already holds the PR head, so the content matches and `e` hands Neovim the real file. Do not tell Paul to `gh pr checkout`; he keeps a worktree per branch and switching the primary clone is not how he works. Keep that worktree clean while reviewing, because a locally modified file stops matching and silently reverts to a snapshot, and re-pull if the PR is pushed to mid-review.

When the PR head is not checked out anywhere, the snapshot is the correct behaviour and there is nothing to fix: it guarantees the text and the line number match the diff. Say so, and offer local mode (Task A2) from the worktree instead if he wants a working editor more than he wants `:submit`.

Binary files are never snapshotted (lossy UTF-8 would corrupt them); they open from the checkout or not at all.

Windowed editors (`code`, `cursor`, `zed`, `subl`, and the JetBrains set) are detected and spawned detached while tuicr keeps drawing; reload with `:e` afterwards. Adding `--wait` / `-w` / `--block` opts them back into blocking. Terminal editors take over the screen and tuicr reloads the diff when they exit.

---

## Task B: driving a review session as an agent

### Get the session slug

The slug is the handle for every `tuicr review` call.

- **PR sessions:** `<forge>:<owner>/<repo>/pr/<N>`, constructible with no lookup. Forge prefixes are `gh` (GitHub), `gl` (GitLab), `bb` (Bitbucket), `az` (Azure DevOps, which carries an extra project segment: `az:org/project/repo/pr/42`).
- **Local sessions:** `<owner>/<repo>@<branch>/<source>/<head-short-sha>`, e.g. `paulchiu/agent-sandbox@main/staged-and-unstaged/b92c827`. `<source>` is one of `worktree`, `staged`, `unstaged`, `staged-and-unstaged`, `pristine`, or a range form: `commits/<base>..<head>`, `worktree-and-commits/<base>..<head>`, `staged-and-unstaged-and-commits/<base>..<head>`.

> `docs/REVIEW_CLI.md` shows bare forms like `agavra/tuicr@main/worktree`. That is stale: non-range sources always append the short head SHA. Read the slug rather than constructing it.

Discover live sessions:

```bash
tuicr review list --repo .          # this checkout, plus PR sessions for its origin
tuicr review list --all             # everything
```

`--repo` is a selector, not just a path: a checkout path, `owner/repo`, `host/owner/repo`, `forge:host/owner/repo`, or a repo/PR URL.

Each row is JSON with `slug`, `kind` (`local`|`pr`), `path`, `updated_at` (RFC3339), `comment_count`, `reviewed_count`, `file_count`, `anchor`, and `active`. **Prefer the row with `"active": true`**, which tuicr maintains in `active_sessions.json` from the live TUI process rather than inferring from timestamps. If several are active, ask which one. An empty store prints `[]`.

tuicr also prints `tuicr-session: <slug>` to stdout on startup, so a captured launch gives you the slug with no guessing.

### Read comments

```bash
tuicr review comments --session 'gh:owner/repo/pr/123'
```

Returns JSON with `id`, `location`, `path`, `start_line`, `end_line`, `side`, `comment_type`, `lifecycle_state`, `created_at`, `content`. There is no push channel: to watch for new human comments, poll every ~30s and diff on `id`.

`--session` also accepts a path to a session JSON file directly. PR slugs and JSON paths resolve without `--repo`; only local slugs consult it.

### Add comments

```bash
tuicr review add --session 'gh:owner/repo/pr/123' \
  --target-file src/auth.rs --line 42 --side new \
  --type issue --username "Claude Opus 5" \
  "Magic number should be a named constant."
```

- Target shape: no `--target-file` = review-level; `--target-file` = file-level; add `--line` = line; add `--end-line` = range.
- The flag is `--type`, not `--comment-type`, and it defaults to `none`. An id absent from a configured `comment_types` now **warns on stderr** but is still stored verbatim as a custom type, so check stderr rather than assuming success. Pass the type's `id`, never its `label`.
- Always pass `--username` explicitly so authorship is unambiguous. It falls back to config `username`, then `"user"`.
- `--side` is `new` (default) or `old`.
- Batch form: `--input '<json>'`, `--input @file.json`, or `--input -`. Flat fields: `content` (required), `type` or `comment_type`, `file`, `line`, `start_line`, `end_line`, `side`. A nested `target` object is also accepted with `type` of `review`, `file`, `line`, or `line_range`/`range`.

With `review_watch_interval_ms` non-zero (default 1000), comments added this way appear **live** in an already-open TUI.

### Remove comments

```bash
tuicr review delete --session <slug> --comment-id <id>   # one comment, id from `review comments`
tuicr review clearc --session <slug>                     # all comments, keep reviewed marks
tuicr review clear  --session <slug>                     # all comments and reviewed marks
```

`clear` and `clearc` are destructive and cover the whole session. Confirm with Paul before either; `delete` with an explicit id is the safe one.

### Which workflow applies

Decide this before adding anything:

1. **Paul is reviewing your changes** -> do NOT add your own comments. Poll `tuicr review comments` and act on what he writes.
2. **You are reviewing a patch** -> `tuicr review add` is appropriate, with an explicit `--username`.

Type semantics when `comment_types` is configured: `issue` = blocking, `suggestion` = implement or explain why not, `note` = answer it, `praise` = no action.

---

## Command surface (0.27.0)

Four subcommands: `tui`, `pr` (alias `mr`), `review`, `update`. Bare `tuicr` opens the target selector. `tuicr pr N` and `tuicr tui pr N` are the same code path.

Shared options on `tuicr`, `tuicr tui`, `tuicr pr`:

```
-r, --revisions <REVSET>  Commit range / revset to review
    --theme <THEME>       Bundled name, else a file in the config themes/ dir
    --appearance <MODE>   light | dark | system
-p, --path <PATH>         Filter the diff to a file or directory
-w, --working-tree        Include uncommitted changes
    --file <PATH>         Annotate a file or directory with no VCS
-A, --all-files           Review every tracked file
    --stdout              Export to stdout instead of the clipboard
    --no-update-check     Skip the startup update check
    --repo-url <URL>      Override the forge repo (HTTPS, SCP-style SSH, or ssh:// forms)
    --remote <NAME>       Use a named remote's fetch URL for PR operations (git only)
```

`-V`/`--version` exists **only on the root command**; `tuicr pr -V` still errors with `unexpected argument '-V' found`.

Accepted `pr` targets: `123`, `'owner/repo#123'`, `'github.com/owner/repo#123'`, `'https://github.com/owner/repo/pull/123'`. GitLab MRs use the same forms via the `mr` alias.

VCS backends: git, Mercurial (`hg`), and Jujutsu (`jj`).

---

## Config

`~/.config/tuicr/config.toml` (TOML; `$XDG_CONFIG_HOME` honoured). Local themes live in the sibling `themes/` directory. Review sessions do **not** live here. On macOS they are under `~/Library/Application Support/tuicr/reviews/`, with `active_sessions.json` beside the manifest. PR editor snapshots are separate again, under `$TMPDIR/tuicr/snapshots/`.

### Paul's current config

```toml
appearance = "dark"
diff_view = "side-by-side"
username = "Paul Chiu"
show_pr_comments = false

[export]
intro = ""
scope_line = false
pr_metadata = false
comments_header = ""
legend = false
remote_comments_header = "## Existing GitHub Comments"
```

The `[export]` block trims the yank down to bare numbered comment lines. See [Export shape](#export-shape).

Two upgrades are now available to him and are **not** applied: `[export] session_header = false` (he wanted the `## Session:` line gone and 0.24.0 could not do it) and `pr_comments_visibility = "hide"` (he was typing `:comments hide` per PR). Offer them; do not edit his config unasked.

`show_pr_comments = false` is deliberate (Paul wants an unbiased first pass) and should not be flipped back without asking. **It is narrower than its name.** It only drops the `comments` field from `gh pr view --json`, i.e. the PR conversation timeline (`issue_comments` in `src/forge/github/pr_info.rs`). Inline review threads come from `list_review_threads`, a separate GraphQL call invoked unconditionally in `src/app/pr.rs`, so CodeRabbit and human review comments still appear in the diff and in the yank. Do not tell Paul this key hides them.

### delta is not available, and never will be via config

**tuicr cannot use delta or any external diff renderer.** Do not add `delta`, `differ`, `pager`, `diff_renderer`, or `external_diff` keys; none exist, and unknown keys are reported as `Warning: Unknown config key '<key>', ignoring`. tuicr still hardcodes `--no-ext-diff` on every git call, which deliberately neutralises `diff.external` and `GIT_EXTERNAL_DIFF`. `[core] pager = delta` in `~/.gitconfig` is also inert because tuicr captures stdout rather than attaching a TTY. Piping does not help: `--stdout` emits review markdown, not a unified diff.

tuicr does its own highlighting with syntect + two-face, the same extended grammar corpus bat and delta ship. Map delta settings across instead:

| delta                     | tuicr                                                                     |
| ------------------------- | ------------------------------------------------------------------------- |
| `side-by-side = true`     | `diff_view = "side-by-side"` (toggle in-app with `:diff`)                 |
| `dark = true` / `--light` | `appearance = "dark"\|"light"\|"system"`, or `theme_dark` + `theme_light` |
| `syntax-theme`            | `theme = "<name>"`, or `syntax_theme` inside a local theme file           |
| whitespace flags          | `ignore_whitespace` (local git/jj/hg diffs, not PR diffs)                 |
| `wrap-max-lines`          | `wrap` (toggle `:wrap` or `:set wrap!`)                                   |
| `line-numbers`            | always on; `relative_line_numbers` switches to vim-style relative         |
| `navigate`                | native vim motions                                                        |

delta remains configured in `~/.gitconfig` and still handles plain `git diff` / `show` / `log -p`. The two tools coexist; they do not compose.

### Every valid top-level key in 0.27.0

38 keys, from `KNOWN_KEYS` in `src/config/mod.rs`. Anything else warns and is dropped. Keys marked **0.27** are new since 0.24.0.

| Key                          | Type                              | Default      | Notes                                                       |
| ---------------------------- | --------------------------------- | ------------ | ----------------------------------------------------------- |
| `theme`                      | string                            | (none)       | Bundled or local theme name, not a path                     |
| `theme_dark` / `theme_light` | string                            | (none)       | Per-appearance themes                                       |
| `appearance`                 | `dark`\|`light`\|`system`         | `system`     | Ignored when `theme` is set                                 |
| `diff_view`                  | `unified`\|`side-by-side`         | `unified`    | Toggle `:diff`                                              |
| `backend`                    | `libgit2`\|`cli`                  | `libgit2`    | Sparse checkouts auto-route to `cli`                        |
| `commit_order`               | `descending`\|`ascending`         | `descending` | Inline commit selector order                                |
| `initial_commit_selection`   | `all`\|`oldest`                   | `all`        | `oldest` walks forward with `(` / `)`                       |
| `ignore_whitespace`          | bool or `"auto"`                  | `false`      | **0.27** gained `"auto"`; local diffs only                  |
| `ignore_whitespace_overrides`| table of ext -> bool              | (none)       | **0.27** only read when `ignore_whitespace = "auto"`         |
| `wrap`                       | bool                              | `false`      | Toggle `:wrap`                                              |
| `relative_line_numbers`      | bool                              | `false`      | Toggle `:set relativenumber!`                               |
| `show_file_list`             | bool                              | `true`       | Toggle `<leader>e`                                          |
| `compact_folders`            | bool                              | `false`      | **0.27** joins single-child directory chains in the tree     |
| `show_commits`               | bool                              | `true`       | Toggle `<leader>s`                                          |
| `show_reviewed`              | bool                              | `true`       | `false` starts with reviewed files hidden                   |
| `show_pr_checks`             | bool                              | `false`      | Fetch GitHub check rollups                                  |
| `show_pr_comments`           | bool                              | `true`       | PR conversation timeline only, not review threads           |
| `pr_comments_visibility`     | `unresolved`\|`all`\|`hide`       | `unresolved` | **0.27** initial value for `:comments`; export ignores it   |
| `single_file_view`           | bool                              | `false`      |                                                             |
| `cursor_line`                | bool                              | `true`       |                                                             |
| `search_highlight`           | bool                              | `true`       | Highlight `/` matches                                       |
| `mouse`                      | bool                              | `true`       |                                                             |
| `transparent_background`     | bool                              | `true`       | `false` paints `panel_bg`                                   |
| `comment_vim`                | bool                              | `false`      | Vim editing in the comment box; `:vim`                      |
| `q_quits`                    | bool                              | `false`      | **0.27** restores the legacy bare `q` quit binding          |
| `comment_tab_width`          | int                               | `4`          |                                                             |
| `leader`                     | **single char**                   | `;`          | Multi-char values are rejected with a warning               |
| `editor`                     | string                            | (none)       | **0.27** overrides `$EDITOR`; shell-split, run without a shell |
| `scroll_offset`              | int                               | `0`          | vim `scrolloff`                                             |
| `review_watch_interval_ms`   | int                               | `1000`       | `0` disables live pickup of agent comments                  |
| `diff_watch_interval_ms`     | int                               | `0`          | Non-zero re-reads the local diff without `:e`               |
| `no_update_check`            | bool                              | `false`      |                                                             |
| `export_legend`              | bool                              | `true`       | Legacy; `[export] legend` supersedes it                     |
| `username`                   | string                            | `"user"`     | Also drives local comment colouring                         |
| `comment_types`              | array of tables                   | (none)       | See below                                                   |
| `forge`                      | table                             | (none)       | Only key: `comment_type_prefix` (bool, default `true`)      |
| `export`                     | table                             | (none)       | See [Export shape](#export-shape)                           |

Bundled themes (all 23 still ship in 0.27.0): `dark`, `light`, `ayu-light`, `ayu-mirage`, `onedark`, `github-light`, `github-dark`, `catppuccin-latte`, `catppuccin-frappe`, `catppuccin-macchiato`, `catppuccin-mocha`, `everforest-dark`, `everforest-light`, `gruvbox-dark`, `gruvbox-light`, `nord-dark`, `nord-light`, `nord-dark-high-contrast`, `nord-light-high-contrast`, `solarized-light`, `solarized-dark`, `tokyo-night-storm`, `tokyo-night-day`. `:theme` opens a picker, `:theme <name>` applies one directly.

### `ignore_whitespace = "auto"` (0.27)

`true` and `false` keep the old global modes. `"auto"` runs the comparison twice and picks per file by extension. The built-in ignore list is `json js jsx mjs cjs ts tsx rs` (`AUTO_IGNORE_WHITESPACE_EXTENSIONS` in `src/vcs/traits.rs`). Everything else, including Python, YAML and extensionless files, compares whitespace normally.

`[ignore_whitespace_overrides]` replaces the decision for one extension; it does not invert the global boolean, and it is read only in `"auto"` mode (configuring it otherwise warns).

```toml
ignore_whitespace = "auto"

[ignore_whitespace_overrides]
py = true     # ignore whitespace in Python too
rs = false    # but not in Rust
```

Keys are normalised to lowercase with no leading dot. A key with a path or glob is rejected.

### `comment_types` (opt-in)

Without this key, comments are untyped: no badge, no `[TYPE]` tag, no export legend.

```toml
[[comment_types]]
id = "issue"          # required, unique, stored in sessions
label = "ISSUE"       # optional, defaults to id uppercased
color = "red"         # optional, terminal name or #RRGGBB
definition = "must fix before merge"   # optional, guidance for LLMs, shown in the export legend
```

Configuring this **replaces** the set entirely; the first entry becomes the default and `None` is appended to the end of the Tab cycle.

---

## Export shape

`[export]` controls the markdown that `y` and `:clip` copy and that `--stdout` prints. It does **not** affect `:submit`; that is `[forge] comment_type_prefix`.

| Key                      | Default                                                                     |
| ------------------------ | --------------------------------------------------------------------------- |
| `intro`                  | `I reviewed your code and have the following comments. Please address them.` |
| `scope_line`             | `true` (the `Reviewing <scope>` line)                                       |
| `pr_metadata`            | `true` (the `URL:` and `Head:` lines, PR mode only)                         |
| `comments_header`        | `## Local tuicr Comments`                                                   |
| `remote_comments_header` | `## Existing GitHub Comments` (PR mode only)                                |
| `session_header`         | `true` (the `## Session: <slug>` heading) **0.27**                           |
| `legend`                 | `true`, and it wins over top-level `export_legend`                          |

Setting a string key to `""` drops that line and its trailing blank. `session_header` and `legend` are booleans.

**`session_header = false` is the fix for the `## Session:` heading** (`src/output/markdown.rs:271`, "drops it for agents that read it as noise"). Earlier versions wrote it unconditionally and this skill used to say it could not be removed. It can now, so offer the key instead of a manual delete.

**Nothing still keeps remote review threads out of the export.** The block is gated only on PR mode plus a non-empty unresolved-thread list, and the filter is hardcoded to `PrCommentsVisibility::Unresolved` (`src/output/markdown.rs:470`), so neither the in-TUI `:comments hide` toggle nor the new `pr_comments_visibility` key reaches it. `remote_comments_header = ""` drops only the heading and leaves the thread bodies, which is worse than leaving them labelled. Say this plainly rather than reaching for a `--stdout | sed` pipeline: Paul prefers stock tool behaviour plus a little manual work over custom glue, because glue makes problems harder to debug. The manual delete or an upstream feature request is the honest answer.

To review blind to existing threads, the lever is `pr_comments_visibility = "hide"` in config, or `:comments hide` per session (which writes `remote_comments_visibility` to the persisted session so it sticks for that PR).

Three export routes, all triggered from inside the TUI:

1. **Clipboard**: `y` or `:clip`, numbered markdown keyed by `file:line`. `Y` copies just the comment at the cursor.
2. **stdout**: launch with `--stdout`, then `y` writes to stdout on exit (the TUI moves to `/dev/tty`, so a pipe is safe).
3. **Real forge review**: `:submit`, or `:submit approve` / `:submit request-changes` / `:submit draft`.

---

## Keybindings

Press `?` in the app, or read `docs/KEYBINDINGS.md`. `<leader>` is `;`.

**Navigate**: `j k h l` / arrows · `Ctrl-d`/`Ctrl-u` half page · `Ctrl-f`/`Ctrl-b` page · `g`/`G` first/last file · `{N}G` go to line N · `{N}{motion}` count prefix · `{`/`}` prev/next file · `[`/`]` prev/next hunk · `m`/`M` next/prev comment · `/` search, `n`/`N` matches, `Esc` clears highlighting · `Enter` expand hidden context · `zt`/`zz`/`zb` scroll position.

**Review**: `r` toggle file reviewed · `R` toggle hunk reviewed · `c` line comment · `C` file comment · `<leader>c` review-level comment · `v`/`V` visual mode for a range comment · `i` edit comment · `A` edit with cursor at end (vim mode) · `dd` delete comment · `e` open focused file in the editor · `y` copy review · `Y` copy comment at cursor.

**Bare `q` no longer quits** (0.27). It prints a reminder to use `:q`. `q_quits = true` restores it. `q` still closes the help screen.

**File tree** (only while focused): `Space` expand dir · `Enter` expand/jump · `o`/`O` expand/collapse all · `i`/`e` include/exclude regex filter · `I`/`E` clear those filters · `/` path search, `n`/`N` matches. Filters hide files from the diff, navigation, and counts too, but never delete their comments. Hiding reviewed files is **command-only** (`:set noreviewed` / `:reviewed` / `:set reviewed!`), deliberately unbound because `H` is a vim motion; while hidden, `r` becomes a burn-down loop that advances to the next unreviewed file.

**Comment navigator** (0.27): appears below the file tree when local comments or visible remote threads exist. `j`/`k` select · `h`/`l` scroll rows · `Enter` jump to the comment.

**Panels**: `Tab`/`Shift-Tab` cycle focus across file list, comment navigator, diff and commit selector · `<leader>e` toggle file list · `<leader>s` toggle commit selector · `<leader>h` file list · `<leader>l` diff · `<leader>j`/`<leader>k` focus down/up.

**Comment box** (default readline mode): `Tab` cycles comment type · `Enter` / `Ctrl-Enter` / `Ctrl-s` saves · `Shift-Enter`, `Alt-Enter`, or `Ctrl-j` newline (all three always work; the panel hint shows `Shift-Enter` only when the terminal supports the keyboard enhancement protocol, otherwise `Alt-Enter`, which is the honest hint under tmux without `extended-keys on`) · `Ctrl-w` delete word · `Ctrl-u` clear line · `Esc` cancels. With `comment_vim = true` it is edtui modal editing, where `Alt-Enter` accepts and `Alt-Esc` discards without the double-press.

**Ex commands** (from `COMMAND_SPECS` in `src/handler.rs`, which is authoritative over the docs). `Tab` completes and cycles command names in the `:` prompt.

`:w`/`:write` · `:q`/`:quit` · `:q!`/`:quit!` · `:x`/`:wq` · `ZZ`/`ZQ` · `:e`/`:reload` · `:edit` · `:clip`/`:export` · `:copy-url` · `:summary` · `:clear` · `:clearc` · `:help`/`:h`/`?` · `:messages` · `:version` · `:update` · `:diff` · `:theme [name]` · `:focus`/`:f` · `:stage` (stage reviewed files) · `:commits`/`:targets` · `:prs` · `:sessions`/`:reviews` · `:submit [comment|approve|request-changes|draft]` · `:comments unresolved|all|hide` · `:wrap` / `:set wrap` / `:set wrap!` · `:vim` / `:novim` / `:set vim` / `:set novim` / `:set vim!` · `:set [no]commits` / `:set commits!` · `:set [no]reviewed` / `:reviewed` / `:set reviewed!` · `:set [no]relativenumber` / `:set relativenumber!` · `:{N}` jump to new-side line · `:o{N}` jump to old-side line.

The target selector now has three tabs: Local, Pull Requests, and Sessions (`:sessions` or `:reviews` opens it there).

---

## Auth and forges

tuicr holds no tokens of its own for GitHub, GitLab, or Bitbucket; it shells out and inherits their auth.

| Forge        | Slug prefix | Transport                         | Local status                 |
| ------------ | ----------- | --------------------------------- | ---------------------------- |
| GitHub       | `gh:`       | `gh` CLI                          | installed, logged in (ssh)   |
| GitLab       | `gl:`       | `glab` CLI                        | **not installed**            |
| Bitbucket    | `bb:`       | `bkt` CLI, Cloud only             | **not installed**            |
| Azure DevOps | `az:`       | REST API + `AZURE_DEVOPS_EXT_PAT` | no PAT set                   |

So GitHub is the only forge that works on this machine today. If PR operations fail, check `gh auth status`.

`:submit draft` is GitHub only. `comment` and `approve` work on GitHub, GitLab, and Bitbucket; `request-changes` works on GitHub and GitLab but not Bitbucket.

---

## Gotchas

- The TUI needs a TTY. Launch it in a herdr pane; never as a plain Bash call. It still prints `tuicr-session: <slug>` before dying, which is a cheap way to compute a slug.
- Quote targets containing `#`.
- **`e` in PR mode may open a read-only temp copy, not your file.** The status bar says `(read-only PR copy)` when it does. See [The `e` key and PR snapshots](#the-e-key-and-pr-snapshots).
- `$EDITOR` comes from `~/.zshrc`, so it exists only in interactive shells. A non-interactive launch path silently falls back to `vi`, which reads the plugin-free `~/.vimrc`. Set the `editor` config key rather than moving the export.
- Malformed TOML surfaces `Failed to load config: <err>` at startup, but the whole file is still discarded and every setting reverts to default. Validate after editing:
  ```bash
  python3 -c 'import tomllib,sys;tomllib.load(open(sys.argv[1],"rb"))' ~/.config/tuicr/config.toml
  ```
- **Only the first startup warning is ever displayed** (`startup_warnings.first()` in `src/main.rs:403`, unchanged in 0.27.0). One typo can therefore mask the next. Check keys against the table above rather than trusting the absence of a warning.
- Unknown keys warn by name, including inside `[forge]`, `[export]` and `[ignore_whitespace_overrides]`. A top-level `syntax_theme` reports as unknown; it only works inside a local theme file in `themes/`.
- `tuicr review` subcommands do not load or validate `config.toml`, so they cannot smoke-test it.
- `--type` accepts anything and stores typos verbatim as custom types; the warning goes to stderr, so capture it.
- `review clear` and `review clearc` wipe a whole session. Confirm before running either.
- Local session slugs carry a short head SHA that upstream docs omit. Read the slug from `review list` or the startup line; do not build it by hand.
- `.tuicrignore` at the repo root excludes files from review diffs, gitignore-style with `!` negation. `.gitignore` is honoured automatically.
- Snapshots under `$TMPDIR/tuicr/snapshots/` are keyed by head SHA and never cleaned up by tuicr; the OS reclaims them. A stale one is harmless but is a good forensic record of what `e` last opened.
- Pin doc reads to the installed tag: `https://raw.githubusercontent.com/agavra/tuicr/v0.27.0/<path>`. Upstream `main` documents unreleased behaviour.
