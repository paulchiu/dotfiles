---
name: openpackage-sync
description: Synchronizes commands and skills between OpenCode and Claude Code using OpenPackage (opkg). Triggers when user asks to sync, update, or mirror opencode and claude configurations in either direction. Automatically manages the paul package and performs bidirectional sync.
---

# OpenPackage Sync (OpenCode ↔ Claude Code)

## Overview

This skill manages bidirectional synchronization of commands and skills between OpenCode and Claude Code using the OpenPackage (opkg) package manager. It automatically detects which platform files need updating and syncs them accordingly.

## Trigger Conditions

Activate this skill when the user:
- Asks to "sync opencode and claude" (either direction)
- Requests to "update claude from opencode"
- Requests to "update opencode from claude"
- Asks to "mirror" or "copy" skills/commands between platforms
- Mentions syncing OpenPackage configurations
- Wants to "pull" or "push" changes between the two platforms

## Quick Start

To sync between OpenCode and Claude Code:

1. **Determine sync direction** - Ask which direction (or detect from request)
2. **Check current package state** - Verify paul package exists and is up to date
3. **Add any missing files** - Use `opkg add` to include new commands/skills
4. **Apply sync** - Use `opkg apply` or `opkg install` to sync to target platform
5. **Verify results** - Confirm files are in correct locations

## Sync Directions

### OpenCode → Claude Code

When user wants to sync FROM opencode TO claude:

```bash
# First, ensure all opencode files are added to the paul package
opkg add paul ~/.opencode/command/<new-command>.md
opkg add paul ~/.opencode/skill/<new-skill>

# Apply changes to claude (from ~/.openpackage/ directory)
cd ~/.openpackage
opkg apply paul --platforms claude
```

**Files will be synced to:**
- Commands: `~/.claude/commands/`
- Skills: `~/.claude/skills/`

### Claude Code → OpenCode

When user wants to sync FROM claude TO opencode:

```bash
# Import claude files into the paul package (reverse sync)
cd ~
opkg save paul --platforms claude

# This will update the paul package with any new files from claude
# Then apply to opencode
cd ~/.openpackage
opkg apply paul --platforms opencode
```

**Files will be synced to:**
- Commands: `~/.opencode/command/`
- Skills: `~/.opencode/skill/`

## Complete Sync Workflow (Bidirectional)

For a full bidirectional sync:

1. **Navigate to home directory:**
   ```bash
   cd ~
   ```

2. **Save current claude state to paul package:**
   ```bash
   opkg save paul --platforms claude
   ```

3. **Save current opencode state to paul package:**
   ```bash
   opkg save paul --platforms opencode
   ```

4. **Apply to claude:**
   ```bash
   opkg apply paul --platforms claude
   ```

5. **Apply to opencode:**
   ```bash
   opkg apply paul --platforms opencode
   ```

## Package Structure

The `paul` package lives at `~/.openpackage/packages/paul/` with:

```
~/.openpackage/packages/paul/
├── openpackage.yml          # Package manifest
├── commands/                # Command files
│   ├── archive-obsidian.md
│   ├── branch-review.md
│   ├── implementation-guidance.md
│   └── linear-create.md
└── skills/                  # Skill directories
    ├── archive-obsidian-vault/
    ├── gcalcli-calendar/
    ├── implementation-guidance-generator/
    ├── linear-create/
    └── openpackage-sync/    # This skill
```

## Adding New Files to Sync

When you create new commands or skills in either platform:

### Adding a new command:
```bash
# From opencode
opkg add paul ~/.opencode/command/my-new-command.md

# From claude
opkg add paul ~/.claude/commands/my-new-command.md
```

### Adding a new skill:
```bash
# From opencode
opkg add paul ~/.opencode/skill/my-new-skill

# From claude
opkg add paul ~/.claude/skills/my-new-skill
```

## Platform-Specific File Locations

### OpenCode
- Commands: `~/.opencode/command/*.md`
- Skills: `~/.opencode/skill/<skill-name>/`
- Package config: `~/.opencode/package.json`

### Claude Code
- Commands: `~/.claude/commands/*.md`
- Skills: `~/.claude/skills/<skill-name>/`
- Root instructions: `~/.claude/CLAUDE.md`

## Verification Steps

After syncing, verify:

1. **List claude commands:**
   ```bash
   ls -la ~/.claude/commands/
   ```

2. **List claude skills:**
   ```bash
   ls -la ~/.claude/skills/
   ```

3. **List opencode commands:**
   ```bash
   ls -la ~/.opencode/command/
   ```

4. **List opencode skills:**
   ```bash
   ls -la ~/.opencode/skill/
   ```

5. **Check package status:**
   ```bash
   opkg list
   opkg show paul
   ```

## Common Issues

### Missing files in sync

If files aren't appearing after sync:

1. Check if they were added to the package:
   ```bash
   opkg show paul
   ```

2. Force re-add if necessary:
   ```bash
   opkg add paul <path-to-file>
   ```

3. Re-apply with force:
   ```bash
   opkg apply paul --platforms <platform> --force
   ```

### Platform detection issues

If opkg can't detect the platform:

1. Manually specify platform:
   ```bash
   opkg apply paul --platforms claude
   opkg apply paul --platforms opencode
   ```

2. Check platform detection files exist:
   - Claude: `~/.claude/` directory or `CLAUDE.md`
   - OpenCode: `~/.opencode/` directory

### File conflicts

If there are conflicts during sync:

```bash
opkg apply paul --platforms <platform> --conflicts overwrite
```

Strategies:
- `keep-both` - Keep both versions (may create duplicates)
- `overwrite` - Replace existing files
- `skip` - Keep existing files, skip new ones
- `ask` - Prompt for each conflict (default)

## Best Practices

1. **Always save before syncing** - Run `opkg save` on the source platform first to capture any new changes

2. **Sync frequently** - Regular small syncs are easier to manage than large infrequent ones

3. **Verify after sync** - Always check that files are in expected locations

4. **Use force sparingly** - Only use `--force` when you're sure you want to overwrite

5. **Keep package.yml updated** - Ensure `openpackage.yml` reflects all desired commands and skills

6. **Test new files** - After syncing, test that commands and skills work on the target platform

## Commands Reference

**Core sync commands:**
- `opkg save <package>` - Save workspace changes to package
- `opkg apply <package>` - Apply package changes to workspace
- `opkg add <package> <path>` - Add file/directory to package
- `opkg remove <package> <path>` - Remove file/directory from package

**Status commands:**
- `opkg list` - List installed packages
- `opkg show <package>` - Show package details and files
- `opkg status` - Show overall status

**Install/Uninstall:**
- `opkg install <package>` - Install package to workspace
- `opkg uninstall <package>` - Remove package from workspace
