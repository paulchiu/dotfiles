---
name: tuicr
description: "Open a pull request in the tuicr review TUI, or drive tuicr's non-interactive review CLI. Use for 'open PR in tui', 'open this in tuicr', 'review this PR in the TUI', 'add a tuicr comment', or any tuicr config/keybinding question."
---

# tuicr

tuicr ("tweaker") is a terminal code-review TUI with vim keybindings. It renders a GitHub-style continuous diff, takes PR-style comments at line/range/file/review level, and exports to the clipboard, stdout, or a real GitHub review.

Two interfaces, and they are not interchangeable:

- **The TUI** (`tuicr`, `tuicr pr`) is where a **human** reviews. It requires a TTY.
- **`tuicr review`** (`list` / `comments` / `add`) is the **agent** interface. It is non-interactive, prints JSON, and is the only part you can drive directly.

Verified against tuicr **0.19.1** (Homebrew `agavra/tap`). Upstream `main` documents features this build does not have, so prefer the behaviour described here over the README. Upgrade with `brew upgrade agavra/tap/tuicr` (`tuicr update` does not exist in 0.19.1).

---

## Task A: "open PR in tui"

The default reading of "open a PR in tui" is: open the PR for the **current branch**, in a new pane, for Paul to drive. Follow these steps in order.

### Step 1: Establish the repo

Run `git rev-parse --show-toplevel`. If it fails, ask which repo to use and stop.

### Step 2: Resolve the PR number

Only skip this if the user already gave a PR number or URL.

```bash
gh pr view --json number,title,state,isDraft,url --jq '"\(.number)\t\(.state)\t\(.title)"'
```

- **Succeeds** → use that number. Note it also resolves merged and closed PRs; if `state` is not `OPEN`, say so before opening.
- **Fails** (exit 1, `no pull requests found for branch "..."` on stderr) → the branch has no PR. List candidates and ask which one:
  ```bash
  gh pr list --author @me --state open --json number,title,headRefName,updatedAt --limit 10
  ```
- If the user asked for a PR **awaiting their review** rather than their own:
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

`tuicr pr` **cannot run headless**. Without a TTY it fetches everything, prints its session line, then dies with `Error: Device not configured (os error 6)`. `--stdout` does not change this. Never run `tuicr pr` as a plain Bash tool call.

**If `$NEX_PANE_ID` is set** (Paul's normal environment), split a pane and send the command. Capture the new pane's UUID from `--json` and target that, rather than a label, because a label needs workspace scope to resolve and can route to the wrong pane:

```bash
pane=$(nex pane split --direction vertical --name tuicr \
         --path "$(git rev-parse --show-toplevel)" --json | jq -r .pane_id)
nex pane send --target "$pane" "tuicr pr 'owner/repo#123'"
```

Then tell Paul the pane is open and which PR it holds. Do not try to read or drive the TUI afterwards; it is his to operate.

**If `$NEX_PANE_ID` is not set**, do not attempt a PTY workaround. Print the command and tell Paul to run it himself with the `!` prefix:

```
! tuicr pr 'owner/repo#123'
```

### Step 5: Report

State the PR number, title, and where it opened. If you will follow up with `tuicr review` calls, capture the session slug per Task B.

---

## Task B: driving a review session as an agent

### Get the session slug

The slug is the handle for every `tuicr review` call.

- PR sessions: `gh:<owner>/<repo>/pr/<N>`: construct it directly, no lookup needed.
- Local sessions: `<owner>/<repo>@<branch>/worktree` or `<owner>/<repo>@<branch>/commits/<a>..<b>`.

To discover live sessions:

```bash
tuicr review list --repo .          # this checkout, plus PR sessions for its origin
tuicr review list --all             # everything
```

Prefer the row with `"active": true`. If several are active, ask which one. `--repo` also accepts `owner/repo`, `host/owner/repo`, or a PR URL. An empty store prints `[]`.

tuicr also prints `tuicr-session: gh:owner/repo/pr/1` to stdout on startup, so a captured launch gives you the slug with no guessing.

### Read comments

```bash
tuicr review comments --session 'gh:owner/repo/pr/123'
```

Returns JSON with `id`, `location`, `path`, `start_line`, `end_line`, `side`, `comment_type`, `lifecycle_state`, `created_at`, `content`. There is no push channel: to watch for new human comments, poll every ~30s and diff on `id`.

### Add comments

```bash
tuicr review add --session 'gh:owner/repo/pr/123' \
  --target-file src/auth.rs --line 42 --side new \
  --type issue --username "Claude Opus 5" \
  "Magic number should be a named constant."
```

- Target shape: no `--target-file` = review-level; `--target-file` = file-level; add `--line` = line; add `--end-line` = range.
- The flag is `--type`, not `--comment-type`, and **it is not validated**. A typo is stored verbatim. Pass the type's `id`, never its `label`.
- Always pass `--username` explicitly so authorship is unambiguous.
- `--side` is `new` (default) or `old`.
- Batch form: `--input '<json>'`, `--input @file.json`, or `--input -`. Flat fields: `content` (required), `type`, `file`, `line`, `start_line`, `end_line`, `side`.

With `review_watch_interval_ms` non-zero (default 1000), comments added this way appear **live** in an already-open TUI.

### Which workflow applies

Decide this before adding anything:

1. **Paul is reviewing your changes** → do NOT add your own comments. Poll `tuicr review comments` and act on what he writes.
2. **You are reviewing a patch** → `tuicr review add` is appropriate, with an explicit `--username`.

Type semantics when `comment_types` is configured: `issue` = blocking, `suggestion` = implement or explain why not, `note` = answer it, `praise` = no action.

---

## Command surface (0.19.1)

Exactly three subcommands: `tui`, `pr` (alias `mr`), `review`. Bare `tuicr` opens the target selector. `tuicr pr N` and `tuicr tui pr N` are the same code path.

Shared options on `tuicr`, `tuicr tui`, `tuicr pr`:

```
-r, --revisions <REVSET>  Commit range to review
    --theme <THEME>       Bundled name, else a file in the config themes/ dir
    --appearance <MODE>   light | dark | system
-p, --path <PATH>         Filter the diff to a file or directory
-w, --working-tree        Include uncommitted changes
    --file <PATH>         Annotate a file or directory with no VCS
-A, --all-files           Review every tracked file
    --stdout              Export to stdout instead of the clipboard
    --no-update-check     Skip the startup update check
    --repo-url <URL>      Override the repo for PR operations
```

`-V`/`--version` exists **only on the root command**; `tuicr pr -V` errors.

Accepted `pr` targets: `123`, `'owner/repo#123'`, `'github.com/owner/repo#123'`, `'https://github.com/owner/repo/pull/123'`. GitLab MRs use the same forms via the `mr` alias.

Common local invocations:

```bash
tuicr -w                       # uncommitted changes
tuicr -r main..HEAD            # this branch against main
tuicr -w -p src/               # uncommitted changes under src/
tuicr --stdout > review.md     # then press y in the TUI to write markdown out
```

---

## Config

`~/.config/tuicr/config.toml` (TOML; `$XDG_CONFIG_HOME` honoured). Local themes live in the sibling `themes/` directory. Review sessions do **not** live here. On macOS they are under `~/Library/Application Support/tuicr/reviews/`.

### delta is not available, and never will be via config

**tuicr cannot use delta or any external diff renderer.** Do not add `delta`, `differ`, `pager`, `diff_renderer`, or `external_diff` keys; none exist and they are dropped. tuicr hardcodes `--no-ext-diff` on every git call, which deliberately neutralises `diff.external` and `GIT_EXTERNAL_DIFF`. `[core] pager = delta` in `~/.gitconfig` is also inert because tuicr captures stdout rather than attaching a TTY. Piping does not help either: `--stdout` emits review markdown, not a unified diff.

tuicr does its own highlighting with syntect + two-face, the same extended grammar corpus bat and delta ship, so quality is comparable. Map delta settings across instead:

| delta | tuicr |
|---|---|
| `side-by-side = true` | `diff_view = "side-by-side"` (toggle in-app with `:diff`) |
| `dark = true` / `--light` | `appearance = "dark"\|"light"\|"system"`, or `theme_dark` + `theme_light` |
| `syntax-theme` | `theme = "<name>"`, or `syntax_theme` inside a local theme file |
| whitespace flags | `ignore_whitespace = true` (local diffs only, not PR diffs) |
| `wrap-max-lines` | `wrap` (toggle `:set wrap!`) |
| `line-numbers` | always on, not configurable |
| `navigate` | native vim motions |

delta remains configured in `~/.gitconfig` and still handles plain `git diff` / `show` / `log -p`. The two tools coexist; they do not compose.

### Every valid top-level key in 0.19.1

23 keys. Anything else is dropped.

| Key | Type | Default | Notes |
|---|---|---|---|
| `theme` | string  | (none) | Bundled or local theme name, not a path |
| `theme_dark` / `theme_light` | string  | (none) | Per-appearance themes |
| `appearance` | `dark`\|`light`\|`system` | `system` | Ignored when `theme` is set |
| `diff_view` | `unified`\|`side-by-side` | `unified` | Toggle `:diff` |
| `backend` | `libgit2`\|`cli` | `libgit2` | Sparse checkouts auto-route to `cli` |
| `ignore_whitespace` | bool | `false` | Local diffs only |
| `wrap` | bool | `false` | Toggle `:set wrap!` |
| `show_file_list` | bool | `true` | Toggle `<leader>e` |
| `cursor_line` | bool | `true` | |
| `mouse` | bool | `true` | |
| `transparent_background` | bool | `true` | `false` paints `panel_bg` |
| `comment_vim` | bool | `false` | Vim editing in the comment box; `:vim` |
| `comment_tab_width` | int | `4` | |
| `leader` | **single char** | `;` | Multi-char values are rejected |
| `scroll_offset` | int | `0` | vim `scrolloff` |
| `review_watch_interval_ms` | int | `1000` | `0` disables live pickup of agent comments |
| `no_update_check` | bool | `false` | |
| `export_legend` | bool | `true` | Undocumented upstream |
| `single_file_view` | bool | `false` | Undocumented upstream |
| `username` | string | `"user"` | Undocumented upstream |
| `comment_types` | array of tables  | (none) | See below |
| `forge` | table  | (none) | Only key: `comment_type_prefix` (bool, default `true`) |

`commit_order`, `initial_commit_selection`, and `show_commits` appear in upstream docs but are **rejected** by 0.19.1. Toggle the commit selector at runtime with `:set commits!` instead.

Bundled themes: `dark`, `light`, `ayu-light`, `ayu-mirage`, `onedark`, `github-light`, `github-dark`, `catppuccin-latte`, `catppuccin-frappe`, `catppuccin-macchiato`, `catppuccin-mocha`, `everforest-dark`, `everforest-light`, `gruvbox-dark`, `gruvbox-light`, `nord-dark`, `nord-light`, `nord-dark-high-contrast`, `nord-light-high-contrast`, `solarized-light`, `solarized-dark`, `tokyo-night-storm`, `tokyo-night-day`.

### `comment_types` (opt-in)

Without this key, comments are untyped: no badge, no `[TYPE]` tag, no export legend.

```toml
[[comment_types]]
id = "issue"          # required, unique, stored in sessions
label = "ISSUE"       # optional, defaults to id uppercased
color = "red"         # optional, terminal name or #RRGGBB
definition = "must fix before merge"   # optional, guidance text shown in the export legend
```

Configuring this **replaces** the set entirely; the first entry becomes the default and `None` is appended to the end of the Tab cycle.

---

## Keybindings

Press `?` in the app for built-in help. `<leader>` is `;`.

**Navigate**: `j k h l` / arrows · `Ctrl-d`/`Ctrl-u` half page · `Ctrl-f`/`Ctrl-b` page · `g`/`G` first/last file · `{N}G` go to line N · `{`/`}` prev/next file · `[`/`]` prev/next hunk · `m`/`M` next/prev comment · `/` search, `n`/`N` matches · `Enter` expand hidden context · `zt`/`zz`/`zb` scroll position.

**Review**: `r` toggle file reviewed · `R` toggle hunk reviewed · `c` line comment · `C` file comment · `<leader>c` review-level comment · `v`/`V` visual mode for a range comment · `i` edit comment · `dd` delete comment · `y` copy the review to the clipboard.

**Panels**: `Tab`/`Shift-Tab` cycle focus · `<leader>e` toggle file list · `<leader>h` file list · `<leader>l` diff · `<leader>j`/`<leader>k` focus down/up. (`<leader>s` does not exist in 0.19.1.)

**Comment box** (default readline mode): `Tab` cycles comment type · `Enter` or `Ctrl-s` saves · `Shift-Enter` or `Ctrl-j` newline · `Esc` cancels.

**Ex commands**: `:submit` (or `:submit comment|approve|request-changes|draft`) · `:clip` / `:export` copy · `:diff` toggle unified/side-by-side · `:e` reload · `:edit` open the focused file in `$EDITOR` · `:comments unresolved|all|hide` control remote thread display · `:set commits!` · `:set wrap!` · `:vim` · `:prs` · `:clear` / `:clearc` · `:w` save · `:q` / `:q!` / `:x` · `ZZ` / `ZQ` · `?` help.

---

## Exporting a review

All three are triggered **from inside the TUI**:

1. **Clipboard**: `y` or `:clip`, producing numbered markdown keyed by `file:line`.
2. **stdout**: launch with `--stdout`, then `y` writes to stdout.
3. **Real GitHub review**: `:submit`, or `:submit approve` / `:submit request-changes` / `:submit draft`. Inline comments become real inline review comments; review-level comments become the summary.

---

## Auth

tuicr holds no tokens. It shells out to `gh` for GitHub and `glab` for GitLab and inherits whatever auth those have. If PR operations fail, run `gh auth login`. `glab` is **not installed** on this machine, so GitLab review does not work here today.

---

## Gotchas

- `tuicr pr` needs a TTY. Launch it in a nex pane; never as a plain Bash call.
- Quote targets containing `#`.
- **Malformed TOML in `config.toml` is discarded silently and entirely**: exit 0, no message, every setting reverts to default. Validate after editing:
  ```bash
  python3 -c 'import tomllib,sys;tomllib.load(open(sys.argv[1],"rb"))' ~/.config/tuicr/config.toml
  ```
- Only the **first** startup warning is ever displayed, and warnings are unreliable even then. Never treat the absence of a warning as proof a key was accepted; check it against the table above.
- `syntax_theme` at the top level of `config.toml` is silently ignored. It only works inside a local theme file in `themes/`.
- `tuicr review` subcommands do not load or validate `config.toml`, so they cannot be used to smoke-test it.
- `--type` accepts anything. Typos are stored, not rejected.
- `.tuicrignore` at the repo root excludes files from review diffs, gitignore-style with `!` negation. `.gitignore` is honoured automatically.
- Upstream `main` docs describe unreleased features. Pin doc reads to `https://raw.githubusercontent.com/agavra/tuicr/v0.19.1/<path>`.
