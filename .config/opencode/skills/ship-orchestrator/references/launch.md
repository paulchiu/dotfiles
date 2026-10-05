# Launch

How to start one ship agent per sub-issue. Check syntax against the installed binary (`herdr tab`, `herdr agent` with no subcommand) when anything here disagrees with it.

## Names

- Agent name: the sub-issue code in lowercase without the dash, e.g. `rr442`. Agent names must be unique in the session.
- Tab label: `[parent short id]/[sub-issue number].[repo abbreviation]🚧`. Parent short id is the team key lowercased plus the number, shortened only when unambiguous (`r428`). Repo abbreviation is short and stable across the run (`sap` serve-api, `lcon` loyalty-connector, `lint` loyalty-integrations); pick one per repo and keep it.

## Per sub-issue

Write each ship prompt to a scratchpad file first, then send it from there. Don't build long prompts inline in the shell.

```zsh
# zsh doesn't word-split "$spec", so pass values as function arguments, not `set -- $spec`.
launch() { # $1 agent name, $2 repo dir, $3 tab label
  local out tab pane
  out=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$2" --label "$3" --no-focus) || return 1
  tab=$(jq -r '.result.tab.tab_id' <<<"$out")
  pane=$(jq -r '.result.root_pane.pane_id' <<<"$out")
  echo "$1 $tab $pane"
  # Fails with agent_not_ready when a trust or bypass dialog is showing; the ids above are still valid.
  herdr agent start "$1" --kind claude --pane "$pane" --timeout 60000 \
    -- --permission-mode bypassPermissions
}
launch rr442 ~/dev/serve-api 'r428/442.sap🚧'
```

Record each line in a run file in the scratchpad (sub-issue, repo, agent name, tab id, pane id, and the PR number once known). The run spans hours and context compaction will lose ids that only live in the conversation.

Then, per agent:

- If `agent start` failed, read the pane (`herdr pane read <pane> --source visible`). A trust or bypass confirmation dialog stays for Paul to answer: tell Paul and move on to the next sub-issue.
- Check `herdr agent get <name>` shows `agent_status` `idle` and `foreground_cwd` is the repo. If the cwd or label is wrong, the pane is a stray shell: confirm it's idle, close only that tab, and recreate it.
- Check the pane footer shows bypass permissions on.
- Send the prompt: `herdr agent prompt <name> "$(cat <file>)"`. It returns `agent_prompted` straight away. Confirm the agent moves to `working`.
- Move the Linear sub-issue to In Progress and assign it to Paul in one `save_issue` call with `state: "In Progress"` (resolves per team) and `assignee: "me"`. Always pass `state` explicitly with any `save_issue` call, since it otherwise resets status. Then confirm every sub-issue at once with `list_issues` (`parentId` set to the parent, `fields: ["id","status","assignee"]`), because the save response can show a stale status. If it's already assigned to someone other than Paul, leave it and tell Paul rather than reassigning it.

## Ship prompt

Fill the brackets; drop a bracketed line that doesn't apply.

```
/ship using worktree [sub-issue URL]

[domain extras, e.g. run /pos-pre-push before push]

before handing the PR to me for review, do separate [personas] persona reviews of the diff: read ~/.claude/skills/review-code/references/persona-lens.md, apply steps A and B only. no review rounds, no decision doc, just address what they'd flag.

[if a requester was found] also do a separate [requester] persona review the same way, since they requested this change in [comment link].

keep PR as draft so i get a chance to review.

open draft pr in new /herdr pane in /tuicr when ready for me to review, and apply 👀 to tab name too (replace the 🚧)
```

## Waiting

Foreground `sleep` is blocked. Wait with the stock `herdr agent wait`, run in the background (Bash `run_in_background: true`); you're re-invoked when it exits. Without `--until` it returns on `idle`, `done` or `blocked`, so a dialog or question wakes you too. Always pass `--timeout`.

- **Monitoring:** one backgrounded wait per agent, so you react as soon as any one of them stops: `herdr agent wait rr442 --timeout 1800000`.
- **Parity or other fan-out:** when you need every agent's answer before replying, chain them in one background command: `herdr agent wait rr442 --timeout 1800000; herdr agent wait rr443 --timeout 1800000`.

On a timeout, read the pane: a long test run is normal, a silent pane for an hour isn't.

## Gotchas

- `herdr pane list` has no `--tab` flag. Use `--workspace` and filter by `tab_id` with jq.
- `herdr agent prompt --timeout` requires `--wait`. Without `--wait`, drop `--timeout`.
- A bare `=====` errors in zsh (`=` expansion). Quote separators: `echo '#####'`.
- tuicr targets go in single quotes: `tuicr pr 'owner/repo#N'`.
