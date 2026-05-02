# Nex Live Agent Delegation

Use this reference when the user asks to delegate to a Nex pane, create a live
agent pane, use `cxd` or `ccd`, or work with "Codex pane" / "Claude pane"
language.

## Alias Policy

- Generic delegation: use `cxd`.
- "Codex pane" or explicit `cxd`: use `cxd`.
- "Claude pane" or explicit `ccd`: use `ccd`.
- Treat both aliases as user-managed launch commands with privilege choices
  already baked in. Do not append model or permission flags unless asked.

## Default Live-Pane Flow

1. Reconcile Nex state.

   ```bash
   nex pane id
   nex pane list --json
   ```

2. If the current shell is itself inside a Nex pane, meaning `nex pane id` exits
   `0` and prints a UUID, create a named pane in the current working directory.

   ```bash
   nex pane split --direction vertical --path "$PWD" --name "cxd-review"
   ```

   If `nex pane id` exits `1` with empty output, the current shell is outside
   Nex. `pane split`, `pane create`, and `pane send` may return exit `0` without
   affecting a pane. In that case, prefer creating or using a dedicated
   workspace, then target the new or intended shell pane from `pane list`:

   ```bash
   nex workspace create --name "delegation" --path "$PWD" --color blue
   nex pane list --workspace "delegation" --json
   ```

   Use the returned pane id as the delegate target. Do not spend time repeatedly
   retrying `pane split` or `pane create` from a non-Nex shell.

3. Launch the agent alias in that pane.

   ```bash
   nex pane send --to "cxd-review" cxd
   ```

   Replace `cxd` with `ccd` when the user asked for a Claude pane, and target
   the pane id from `pane list` when no stable label exists yet.

4. Wait briefly, then confirm the agent appears ready if needed.

   ```bash
   sleep 2
   nex pane capture --target "cxd-review" --lines 40
   ```

   Treat capture output as the source of truth. If `pane send` returned success
   but capture does not show the typed command or agent UI, assume send silently
   no-op'd. Retry at most once, then use the focused-pane AppleScript fallback
   below instead of continuing to debug the CLI:

   ```bash
   NEX_AGENT_ALIAS=cxd osascript \
     -e 'tell application "Nex" to activate' \
     -e 'delay 0.3' \
     -e 'tell application "System Events" to keystroke (system attribute "NEX_AGENT_ALIAS")' \
     -e 'tell application "System Events" to key code 36'
   ```

   Set `NEX_AGENT_ALIAS=ccd` for a Claude pane. The fallback activates Nex and
   steals focus from whatever app is frontmost, so skip it if the user may be
   typing elsewhere. In these AppleScript snippets, `key code 36` presses
   Return.

   Only use this fallback when the target pane is the global keystroke target.
   Verify that explicitly with `nex pane list --json`: the target pane must have
   both `is_active_workspace: true` and `is_focused: true`. Per-workspace focus
   alone is not enough, because idle panes in other workspaces may also report
   `is_focused: true`. If the check fails, activate the right workspace first,
   or create a fresh workspace and use its initial shell pane. Do not infer focus
   from "I just created this pane." After keystroking, capture again and verify
   the agent prompt before sending the task.

5. Send the task prompt to the running agent.

   ```bash
   nex pane send --to "cxd-review" "Review the current branch for regressions. Report findings in this pane. Do not edit files."
   ```

   Apply the same capture check to the first task prompt. If launch required the
   focused-pane fallback, send the first prompt through the focused pane too,
   then verify that the agent acknowledged it:

   ```bash
   NEX_TASK_PROMPT='Review the current branch for regressions. Report findings in this pane. Do not edit files.' osascript \
     -e 'tell application "Nex" to activate' \
     -e 'delay 0.2' \
     -e 'tell application "System Events" to keystroke (system attribute "NEX_TASK_PROMPT")' \
     -e 'tell application "System Events" to key code 36'
   ```

   Use shell-appropriate quoting if the prompt contains single quotes or other
   shell-sensitive characters.

This works because the first `pane send` starts the alias in the shell, and the
second `pane send` is delivered to the agent after it is running. If the launch
has not completed, the prompt may be interpreted by the shell, so wait or
capture output before sending important prompts.

## Prompt Shape

For coding work, include:

- Task goal and expected output.
- Owned files or responsibility boundaries.
- Whether the pane may edit files.
- Instruction not to revert user changes or changes from other agents.
- How to report progress and completion in the live pane.

Example:

```text
You are working in a live Nex pane via cxd.
Task: implement the focused validation fix described in the parent chat.
Ownership: only edit src/validation/* and related tests.
Do not revert user changes or edits from other agents.
Run the relevant tests if practical.
Report what changed and any blockers in this pane.
```

## Scaling Beyond One Pane

The normal workflow is one or two live panes for one task. More panes are
acceptable when the work can be split cleanly or when separate external chats
need separate delegates.

For Telegram/OpenACP workflows, assume Paul may have multiple chats open and may
want one delegate per chat or session. Do not collapse those into a single
delegate. Use stable, unique pane labels that encode the route without exposing
secrets, for example `tg-poe-ccd`, `tg-fitkit-cxd`, or
`openacp-<project>-<purpose>`. If working from the sandbox and the prompt names
a short project handle such as `poe` or `fitkit`, resolve it through
`/Users/paul/dev/sandbox/.agents/context/dev-misc-projects.md` and start that
delegate in the canonical project path. Identify the originating chat from the
prompt itself: the user, OpenACP handoff, or Telegram bridge should name a
project handle, purpose, or session id. If the prompt is ambiguous and another
delegate may already serve a different chat, ask before creating a new pane
rather than guessing a label. Collisions on generic labels such as `cxd-review`
are the failure mode this section exists to prevent.

For multiple panes:

- Use stable labels like `cxd-tests`, `cxd-ui`, or `ccd-review`.
- Prefer label prefixes that identify the external chat/session when routing
  from Telegram or OpenACP.
- Assign disjoint file ownership or responsibility to each pane.
- Use `nex pane list --json` before targeting panes by label.
- Use `nex pane capture --target <label> --lines N` to check status.
- Send follow-up prompts directly to the relevant pane.
- Prefer live reporting in panes. Use prompt files or result files only when the
  user asks or the prompt/output is too large for reliable direct sending.

If `pane send` silently fails in a workspace that already has multiple delegate
panes, do not use AppleScript blindly. First confirm the intended pane is the
global keystroke target using the step 4 `is_active_workspace` and `is_focused`
check, or create a separate workspace/pane for that specific external chat and
use its initial focused shell pane for the fallback bootstrap. Once the agent is
running and labels are visible in `pane list`, continue using pane ids or labels
plus capture verification.

## Useful Commands

```bash
nex pane split --direction vertical --path "$PWD" --name "cxd-worker"
nex pane send --to "cxd-worker" cxd
nex pane capture --target "cxd-worker" --lines 80
nex pane list --json
nex pane close --target "cxd-worker"
```
