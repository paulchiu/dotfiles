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

2. Create a named pane in the current working directory.

   ```bash
   nex pane split --direction vertical --path "$PWD" --name "cxd-review"
   ```

3. Launch the agent alias in that pane.

   ```bash
   nex pane send --to "cxd-review" cxd
   ```

4. Wait briefly, then confirm the agent appears ready if needed.

   ```bash
   sleep 2
   nex pane capture --target "cxd-review" --lines 40
   ```

5. Send the task prompt to the running agent.

   ```bash
   nex pane send --to "cxd-review" "Review the current branch for regressions. Report findings in this pane. Do not edit files."
   ```

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

The normal workflow is one or two live panes. More panes are acceptable when the
work can be split cleanly.

For multiple panes:

- Use stable labels like `cxd-tests`, `cxd-ui`, or `ccd-review`.
- Assign disjoint file ownership or responsibility to each pane.
- Use `nex pane list --json` before targeting panes by label.
- Use `nex pane capture --target <label> --lines N` to check status.
- Send follow-up prompts directly to the relevant pane.
- Prefer live reporting in panes. Use prompt files or result files only when the
  user asks or the prompt/output is too large for reliable direct sending.

## Useful Commands

```bash
nex pane split --direction vertical --path "$PWD" --name "cxd-worker"
nex pane send --to "cxd-worker" cxd
nex pane capture --target "cxd-worker" --lines 80
nex pane list --json
nex pane close --target "cxd-worker"
```
