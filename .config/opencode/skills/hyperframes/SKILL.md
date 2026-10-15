---
name: hyperframes
description: Make, edit, render, or debug videos, animations, motion graphics, captions, or HyperFrames HTML compositions; routes to the full HyperFrames skills.
---

# HyperFrames (local router)

The real skills live in a sparse clone of `heygen-com/hyperframes` at `~/dev-misc/hyperframes` (`<ROOT>` below). Only this stub is registered, so the skill listing stays small.

## 1. Refresh the clone (at most daily)

```bash
R=~/dev-misc/hyperframes
[ -n "$(find "$R/.git/FETCH_HEAD" -mmin -1440 2>/dev/null)" ] || { git -C "$R" fetch -q --depth 1 origin main && git -C "$R" reset -q --hard FETCH_HEAD; }
jq -r .version "$R/plugin.json"
```

If the fetch fails, say so and continue on the current version. Never edit the clone; it is overwritten on refresh.

## 2. Hand off to the upstream router

Read `<ROOT>/skills/hyperframes/SKILL.md` and follow it. `<ROOT>` carries `plugin.json`, so it counts as a plugin install: follow `references/plugin-installation.md` with `<PLUGIN_ROOT>` = `<ROOT>`. In particular:

- Never run `hyperframes skills update`, `skills check`, or `npx skills add`. They install duplicate skills into `~/.claude/skills`, which this setup exists to avoid.
- Run the CLI through `node <ROOT>/skills/hyperframes/scripts/plugin-cli.mjs <command>` from the user's project directory.

## 3. Resolving skill references

Upstream skills name each other as `/hyperframes-core`, `/hyperframes:general-video`, `/media-use`, and so on. None of those are registered skills here: read `<ROOT>/skills/<name>/SKILL.md` instead (drop any `hyperframes:` prefix). Relative paths inside a skill (`references/`, `scripts/`) resolve against that skill's own directory.
