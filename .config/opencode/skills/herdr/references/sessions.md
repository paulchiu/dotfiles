# Server, sessions, remote, and config

Everything here is safe to answer from outside a Herdr pane. Anything that
mutates a running session is not.

## Server lifecycle

Herdr needs a background server to hold terminals open.

```bash
brew services start herdr                    # persistent, restarts at login
/opt/homebrew/opt/herdr/bin/herdr server     # foreground, one-off
herdr status                                 # client and server status
herdr server reload-config                   # re-read config.toml, no restart
```

`herdr` on its own launches or attaches the default session from the current
directory. It never needs socket management.

Detach with `ctrl+b q`, or just close the terminal. The server and every agent
keep running. Run `herdr` again to reattach.

```bash
herdr server stop      # ends the session AND stops its pane processes
```

Never run that from inside an active session unless the user explicitly wants
every pane killed. After a full stop, the next start restores the saved session
shape.

## Named sessions

Separate servers with their own panes, tabs, workspaces, sockets, and runtime
state. They still share one global config file. Prefer workspaces; reach for a
named session only when you want genuine isolation, for example a throwaway
session for experiments.

```bash
herdr session list --json
herdr session attach work
herdr session stop work --json
herdr session delete side-project --json
herdr --session work
```

`default` is a valid name when targeting the default session for `stop`.

## Remote attach over SSH

Two modes. SSH in and run `herdr` there (fully remote, no local clipboard
access beyond terminal text paste), or attach from your local machine:

```bash
herdr --remote workbox
herdr --remote ssh://you@server:2222
herdr --remote workbox --session agents
```

In `--remote` mode your local Herdr is a thin client: it connects over SSH,
starts or attaches the remote server, and streams the UI back. Because the
client is local, it can bridge local desktop features such as image clipboard
paste, by copying the image to a remote temp file and pasting that path.

Keybindings default to **local**, snapshotted at attach time; detach and
reattach after editing them. `--remote-keybindings server` uses the host's
config instead. Local custom command bindings are never sent, since those
commands would run on the remote host.

Supported: Linux, macOS, and Windows clients connecting to Linux or macOS
hosts on x86_64 or aarch64. Windows is not supported as a remote host.

Herdr checks the remote platform, prefers a matching `herdr` already on the
remote `PATH`, then checks common direct, Homebrew, mise, and Nix paths. If
none matches, an interactive run offers to install to `~/.local/bin/herdr`;
a non-interactive run **fails** rather than modifying the host.

`HERDR_REMOTE_BINARY=<local path>` pushes a local build instead.
`[remote].manage_ssh_config = false` disables Herdr's generated SSH config and
control socket.

**Auth gotcha:** a passphrase-protected key hangs in any shell that cannot show
the prompt (scripts, CI, mobile terminals). Run `ssh-add` first. On any failure,
verify plain `ssh workbox` works before debugging Herdr.

## Direct terminal attach

Opens one server-owned terminal in the current terminal, rather than the whole
workspace UI. Unix-only.

```bash
herdr agent attach reviewer
herdr terminal attach term_abc123 --takeover
```

Detach with `ctrl+b q`; send a literal `ctrl+b` with `ctrl+b ctrl+b`. Only one
writable client owns input and resize at a time, hence `--takeover`.

For bridges that only need rendered bytes, use a read-only observer. Multiple
observers can watch one terminal without taking ownership:

```bash
herdr terminal session observe w1:p1 --cols 120 --rows 40
```

It prints newline-delimited JSON `terminal.frame` records with base64 ANSI
bytes, then `terminal.closed`. For an interactive bridge use
`herdr terminal session control <target>`, which reads newline-delimited JSON
commands on stdin (`terminal.input`, `terminal.resize`, `terminal.scroll`,
`terminal.release`).

## Config

Config lives at `~/.config/herdr/config.toml`.

```bash
herdr --default-config      # print defaults to crib from
herdr config reset-keys     # back up config, drop custom keybindings
herdr server reload-config
```

The prefix is `ctrl+b`. Everything is rebindable, including the prefix:

```toml
[keys]
prefix = "ctrl+a"

[ui]
mouse_capture = false
```

Bindings accept a list, so prefix and direct chords can coexist:

```toml
[keys]
focus_pane_left = ["prefix+h", "ctrl+alt+h"]
new_tab         = ["prefix+c", "ctrl+alt+c"]
```

For prefix-free chords, upstream recommends the `ctrl+alt` family: they
surveyed the defaults of Ghostty, iTerm2, Terminal.app, kitty, WezTerm,
Alacritty, Warp, Windows Terminal, GNOME Terminal, and Konsole, and `ctrl+alt`
is close to untouched. Avoid `ctrl+alt+arrows`, `ctrl+alt+t`, `ctrl+alt+l`,
`ctrl+alt+a`, `ctrl+alt+s`, `ctrl+alt+u`, and `ctrl+alt+f1..f12`, which desktop
environments and terminals already claim.

Keys worth knowing: `prefix+?` lists every active binding, `prefix+[` enters
copy mode, `prefix+q` detaches, `prefix+w` is workspace navigation.

## Install and upgrade

Installed here via Homebrew, so upgrade through brew:

```bash
brew upgrade herdr
```

`herdr update` is the self-updater for direct installs. Do not use it on a brew
install; it fights the formula. `herdr channel set stable|preview` picks the
update channel.

```bash
herdr completion zsh      # completions (brew already installed these)
herdr --version
herdr --skill             # upstream agent skill file, ships with the binary
```

`herdr --no-session` runs monolithically with no server/client split. It is a
debugging and compatibility escape hatch, not a normal mode.

## Docs

- <https://herdr.dev/docs/quick-start/>
- <https://herdr.dev/docs/agent-automation/>
- <https://herdr.dev/docs/persistence-remote/>
- <https://herdr.dev/docs/config-reference/> and <https://herdr.dev/docs/cli-reference/>
