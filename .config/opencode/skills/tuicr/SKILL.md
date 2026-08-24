---
name: tuicr
description: "Open a pull request (pr) or a local branch diff in the tuicr review TUI"
---

# tuicr

tuicr ("tweaker") is a terminal code-review TUI with vim keybindings. It renders a GitHub-style continuous diff, takes PR-style comments at line/range/file/review level, and exports to the clipboard, stdout, or a real forge review.

Two interfaces, and they are not interchangeable:

- **The TUI** (`tuicr`, `tuicr pr`) is where a **human** reviews. It requires a TTY.
- **`tuicr review`** (`list` / `comments` / `add`) is the **agent** interface. It is non-interactive, prints JSON, and is the only part you can drive directly.

Verified against tuicr **0.23.1**, installed from **homebrew-core** (`brew install tuicr`).

> The `agavra/tap` formula is stale at 0.19.1 and was superseded when tuicr landed in core. If `tuicr --version` reports 0.19.x, the old tap is shadowing core: `brew uninstall agavra/tap/tuicr && brew install tuicr && brew untap agavra/tap`. Upgrades are `brew upgrade tuicr`; `tuicr update` (and `:update`) also exist in 0.23.1 but let Homebrew own the binary.

---

## Task A: "open PR in tui"

The default reading of "open a PR in tui" is: open the PR for the **current branch**, in a new pane, for Paul to drive.

### Step 1: Establish the repo

Run `git rev-parse --show-toplevel`. If it fails, ask which repo to use and stop.

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

**If `$NEX_PANE_ID` is set** (Paul's normal environment), split a pane and send the command. Capture the new pane's UUID from `--json` and target that, rather than a label, because a label needs workspace scope to resolve and can route to the wrong pane:

```bash
pane=$(nex pane split --direction vertical --name tuicr \
         --path "$(git rev-parse --show-toplevel)" --json | jq -r .pane_id)
nex pane send --target "$pane" "tuicr pr 'owner/repo#123'"
```

Then tell Paul the pane is open and which PR it holds. Do not try to read or drive the TUI afterwards; it is his to operate.

**If `$NEX_PANE_ID` is not set**, do not attempt a PTY workaround. Print the command and tell him to run it himself with the `!` prefix:

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
- The flag is `--type`, not `--comment-type`, it defaults to `none`, and **it is still not validated**. `CommentType::from_id` stores any unknown string verbatim as a custom type. Pass the type's `id`, never its `label`.
- Always pass `--username` explicitly so authorship is unambiguous. It falls back to config `username`, then `"user"`.
- `--side` is `new` (default) or `old`.
- Batch form: `--input '<json>'`, `--input @file.json`, or `--input -`. Flat fields: `content` (required), `type` or `comment_type`, `file`, `line`, `start_line`, `end_line`, `side`. A nested `target` object is also accepted with `type` of `review`, `file`, `line`, or `line_range`/`range`.

With `review_watch_interval_ms` non-zero (default 1000), comments added this way appear **live** in an already-open TUI.

### Which workflow applies

Decide this before adding anything:

1. **Paul is reviewing your changes** -> do NOT add your own comments. Poll `tuicr review comments` and act on what he writes.
2. **You are reviewing a patch** -> `tuicr review add` is appropriate, with an explicit `--username`.

Type semantics when `comment_types` is configured: `issue` = blocking, `suggestion` = implement or explain why not, `note` = answer it, `praise` = no action.

---

## Command surface (0.23.1)

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
    --repo-url <URL>      Override the forge repo for PR operations
```

`-V`/`--version` exists **only on the root command**; `tuicr pr -V` errors with `unexpected argument '-V' found`.

Accepted `pr` targets: `123`, `'owner/repo#123'`, `'github.com/owner/repo#123'`, `'https://github.com/owner/repo/pull/123'`. GitLab MRs use the same forms via the `mr` alias.

VCS backends: git, Mercurial (`hg`), and Jujutsu (`jj`).

---

## Config

`~/.config/tuicr/config.toml` (TOML; `$XDG_CONFIG_HOME` honoured). Local themes live in the sibling `themes/` directory. Review sessions do **not** live here. On macOS they are under `~/Library/Application Support/tuicr/reviews/`, with `active_sessions.json` beside the manifest.

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

`show_pr_comments = false` is deliberate and should not be flipped back without asking. Paul wants an unbiased first pass, so existing CodeRabbit and human threads are never fetched and never appear in the TUI or the yank. It doubles as the only way to keep remote threads out of the export. Consequences to remember: `:comments unresolved|all` reports nothing to show, and `remote_comments_header` is dead config while this is off.

### delta is not available, and never will be via config

**tuicr cannot use delta or any external diff renderer.** Do not add `delta`, `differ`, `pager`, `diff_renderer`, or `external_diff` keys; none exist, and unknown keys are now reported as `Warning: Unknown config key '<key>', ignoring`. tuicr hardcodes `--no-ext-diff` on every git call (`src/vcs/git/`), which deliberately neutralises `diff.external` and `GIT_EXTERNAL_DIFF`. `[core] pager = delta` in `~/.gitconfig` is also inert because tuicr captures stdout rather than attaching a TTY. Piping does not help: `--stdout` emits review markdown, not a unified diff.

tuicr does its own highlighting with syntect + two-face, the same extended grammar corpus bat and delta ship. Map delta settings across instead:

| delta                     | tuicr                                                                     |
| ------------------------- | ------------------------------------------------------------------------- |
| `side-by-side = true`     | `diff_view = "side-by-side"` (toggle in-app with `:diff`)                 |
| `dark = true` / `--light` | `appearance = "dark"\|"light"\|"system"`, or `theme_dark` + `theme_light` |
| `syntax-theme`            | `theme = "<name>"`, or `syntax_theme` inside a local theme file           |
| whitespace flags          | `ignore_whitespace = true` (local git/jj/hg diffs, not PR diffs)          |
| `wrap-max-lines`          | `wrap` (toggle `:wrap` or `:set wrap!`)                                   |
| `line-numbers`            | always on; `relative_line_numbers` switches to vim-style relative         |
| `navigate`                | native vim motions                                                        |

delta remains configured in `~/.gitconfig` and still handles plain `git diff` / `show` / `log -p`. The two tools coexist; they do not compose.

### Every valid top-level key in 0.23.1

33 keys, from `KNOWN_KEYS` in `src/config/mod.rs`. Anything else warns and is dropped.

| Key                          | Type                          | Default      | Notes                                                       |
| ---------------------------- | ----------------------------- | ------------ | ----------------------------------------------------------- |
| `theme`                      | string                        | (none)       | Bundled or local theme name, not a path                     |
| `theme_dark` / `theme_light` | string                        | (none)       | Per-appearance themes                                       |
| `appearance`                 | `dark`\|`light`\|`system`     | `system`     | Ignored when `theme` is set                                 |
| `diff_view`                  | `unified`\|`side-by-side`     | `unified`    | Toggle `:diff`                                              |
| `backend`                    | `libgit2`\|`cli`              | `libgit2`    | Sparse checkouts auto-route to `cli`                        |
| `commit_order`               | `descending`\|`ascending`     | `descending` | Inline commit selector order (**new**, was rejected in 0.19) |
| `initial_commit_selection`   | `all`\|`oldest`               | `all`        | `oldest` walks forward with `(` / `)` (**new**)             |
| `ignore_whitespace`          | bool                          | `false`      | Local diffs only                                            |
| `wrap`                       | bool                          | `false`      | Toggle `:wrap`                                              |
| `relative_line_numbers`      | bool                          | `false`      | Toggle `:set relativenumber!` (**new**)                     |
| `show_file_list`             | bool                          | `true`       | Toggle `<leader>e`                                          |
| `show_commits`               | bool                          | `true`       | Toggle `<leader>s` (**new**, was rejected in 0.19)          |
| `show_reviewed`              | bool                          | `true`       | `false` starts with reviewed files hidden (**new**)         |
| `show_pr_checks`             | bool                          | `false`      | Fetch GitHub check rollups (**new**)                        |
| `show_pr_comments`           | bool                          | `true`       | Fetch PR review threads; Paul sets `false` (**new**)        |
| `single_file_view`           | bool                          | `false`      | Now documented upstream                                     |
| `cursor_line`                | bool                          | `true`       |                                                             |
| `search_highlight`           | bool                          | `true`       | Highlight `/` matches (**new**)                             |
| `mouse`                      | bool                          | `true`       |                                                             |
| `transparent_background`     | bool                          | `true`       | `false` paints `panel_bg`                                   |
| `comment_vim`                | bool                          | `false`      | Vim editing in the comment box; `:vim`                      |
| `comment_tab_width`          | int                           | `4`          |                                                             |
| `leader`                     | **single char**               | `;`          | Multi-char values are rejected with a warning               |
| `scroll_offset`              | int                           | `0`          | vim `scrolloff`                                             |
| `review_watch_interval_ms`   | int                           | `1000`       | `0` disables live pickup of agent comments                  |
| `diff_watch_interval_ms`     | int                           | `0`          | Non-zero re-reads the local diff without `:e` (**new**)     |
| `no_update_check`            | bool                          | `false`      |                                                             |
| `export_legend`              | bool                          | `true`       | Legacy; `[export] legend` supersedes it                     |
| `username`                   | string                        | `"user"`     | Also drives local comment colouring                         |
| `comment_types`              | array of tables               | (none)       | See below                                                   |
| `forge`                      | table                         | (none)       | Only key: `comment_type_prefix` (bool, default `true`)      |
| `export`                     | table                         | (none)       | See [Export shape](#export-shape) (**new**)                 |

Bundled themes: `dark`, `light`, `ayu-light`, `ayu-mirage`, `onedark`, `github-light`, `github-dark`, `catppuccin-latte`, `catppuccin-frappe`, `catppuccin-macchiato`, `catppuccin-mocha`, `everforest-dark`, `everforest-light`, `gruvbox-dark`, `gruvbox-light`, `nord-dark`, `nord-light`, `nord-dark-high-contrast`, `nord-light-high-contrast`, `solarized-light`, `solarized-dark`, `tokyo-night-storm`, `tokyo-night-day`.

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
| `legend`                 | `true`, and it wins over top-level `export_legend`                          |

Setting a string key to `""` drops that line and its trailing blank.

**The `## Session: <slug>` heading is not configurable.** `src/output/markdown.rs` writes it unconditionally whenever a slug can be derived, gated only on `session_slug: Option<&str>` being `Some`, with no key behind it (same on upstream `main`). Do not offer a shell wrapper or clipboard post-processing to strip it. Paul prefers stock tool behaviour plus a little manual work over custom glue, because glue makes problems harder to debug. Say it cannot be done, name the limit, and offer the manual delete or an upstream feature request.

**No `[export]` key excludes remote forge threads.** The block is gated only on PR mode plus a non-empty unresolved-thread list (`src/output/markdown.rs`), and the filter is hardcoded to `PrCommentsVisibility::Unresolved`, so the in-TUI `:comments hide` toggle does not change the export either. `remote_comments_header = ""` drops only the heading and leaves the thread bodies, which is worse than leaving it labelled. The only real lever is top-level `show_pr_comments = false`, which changes the `gh pr view --json` field list so the threads are never fetched. That is what Paul runs.

Three export routes, all triggered from inside the TUI:

1. **Clipboard**: `y` or `:clip`, numbered markdown keyed by `file:line`. `Y` copies just the comment at the cursor.
2. **stdout**: launch with `--stdout`, then `y` writes to stdout on exit (the TUI moves to `/dev/tty`, so a pipe is safe).
3. **Real forge review**: `:submit`, or `:submit approve` / `:submit request-changes` / `:submit draft`.

---

## Keybindings

Press `?` in the app, or read `docs/KEYBINDINGS.md`. `<leader>` is `;`.

**Navigate**: `j k h l` / arrows · `Ctrl-d`/`Ctrl-u` half page · `Ctrl-f`/`Ctrl-b` page · `g`/`G` first/last file · `{N}G` go to line N · `{N}{motion}` count prefix · `{`/`}` prev/next file · `[`/`]` prev/next hunk · `m`/`M` next/prev comment · `/` search, `n`/`N` matches, `Esc` clears highlighting · `Enter` expand hidden context · `zt`/`zz`/`zb` scroll position.

**Review**: `r` toggle file reviewed · `R` toggle hunk reviewed · `c` line comment · `C` file comment · `<leader>c` review-level comment · `v`/`V` visual mode for a range comment · `i` edit comment · `A` edit with cursor at end (vim mode) · `dd` delete comment · `e` open focused file in `$EDITOR` · `y` copy review · `Y` copy comment at cursor.

**File tree** (only while focused): `Space` expand dir · `Enter` expand/jump · `o`/`O` expand/collapse all · `i`/`e` include/exclude regex filter · `I`/`E` clear those filters · `/` path search, `n`/`N` matches. Filters hide files from the diff, navigation, and counts too, but never delete their comments.

**Panels**: `Tab`/`Shift-Tab` cycle focus · `<leader>e` toggle file list · `<leader>s` toggle commit selector · `<leader>h` file list · `<leader>l` diff · `<leader>j`/`<leader>k` focus down/up.

**Comment box** (default readline mode): `Tab` cycles comment type · `Enter` / `Ctrl-Enter` / `Ctrl-s` saves · `Shift-Enter` or `Ctrl-j` newline · `Ctrl-w` delete word · `Ctrl-u` clear line · `Esc` cancels. With `comment_vim = true` it is edtui modal editing, where `Alt-Enter` accepts and `Alt-Esc` discards without the double-press.

**Ex commands** (from the `CommandSpec` registry in `src/handler.rs`, which is authoritative over the docs):

`:w`/`:write` · `:q`/`:quit` · `:q!`/`:quit!` · `:x`/`:wq` · `ZZ`/`ZQ` · `:e`/`:reload` · `:edit` · `:clip`/`:export` · `:copy-url` · `:summary` · `:clear` · `:clearc` · `:help`/`:h`/`?` · `:messages` · `:version` · `:update` · `:diff` · `:focus`/`:f` · `:stage` (stage reviewed files) · `:commits`/`:targets` · `:prs` · `:submit [comment|approve|request-changes|draft]` · `:comments unresolved|all|hide` · `:wrap` / `:set wrap` / `:set wrap!` · `:vim` / `:novim` / `:set vim` / `:set novim` · `:set [no]commits` / `:set commits!` · `:set [no]reviewed` / `:reviewed` / `:set reviewed!` · `:set [no]relativenumber` / `:set relativenumber!` · `:{N}` jump to new-side line · `:o{N}` jump to old-side line.

---

## Auth and forges

tuicr holds no tokens of its own for GitHub, GitLab, or Bitbucket; it shells out and inherits their auth.

| Forge        | Slug prefix | Transport                    | Local status                 |
| ------------ | ----------- | ---------------------------- | ---------------------------- |
| GitHub       | `gh:`       | `gh` CLI                     | installed, logged in         |
| GitLab       | `gl:`       | `glab` CLI                   | **not installed**            |
| Bitbucket    | `bb:`       | `bkt` CLI, Cloud only        | **not installed**            |
| Azure DevOps | `az:`       | REST API + `AZURE_DEVOPS_EXT_PAT` | no PAT set              |

So GitHub is the only forge that works on this machine today. If PR operations fail, check `gh auth status`.

`:submit draft` is GitHub only. `comment` and `approve` work on GitHub, GitLab, and Bitbucket; `request-changes` works on GitHub and GitLab but not Bitbucket.

---

## Gotchas

- The TUI needs a TTY. Launch it in a nex pane; never as a plain Bash call. It still prints `tuicr-session: <slug>` before dying, which is a cheap way to compute a slug.
- Quote targets containing `#`.
- Malformed TOML in `config.toml` now surfaces `Failed to load config: <err>` at startup (0.19.1 was silent), but the whole file is still discarded and every setting reverts to default. Validate after editing:
  ```bash
  python3 -c 'import tomllib,sys;tomllib.load(open(sys.argv[1],"rb"))' ~/.config/tuicr/config.toml
  ```
- **Only the first startup warning is ever displayed** (`startup_warnings.first()` in `src/main.rs`). One typo can therefore mask the next. Check keys against the table above rather than trusting the absence of a warning.
- Unknown keys now warn by name, including inside `[forge]` and `[export]`. A top-level `syntax_theme` reports as unknown; it only works inside a local theme file in `themes/`.
- `tuicr review` subcommands do not load or validate `config.toml`, so they cannot smoke-test it.
- `--type` accepts anything and stores typos verbatim as custom types.
- Local session slugs carry a short head SHA that upstream docs omit. Read the slug from `review list` or the startup line; do not build it by hand.
- `.tuicrignore` at the repo root excludes files from review diffs, gitignore-style with `!` negation. `.gitignore` is honoured automatically.
- Pin doc reads to the installed tag: `https://raw.githubusercontent.com/agavra/tuicr/v0.23.1/<path>`. Upstream `main` documents unreleased behaviour.
