---
name: personal
description: Router for personal-life tasks and tools. Use when asked to convert a workout/gym log into Dataview-compatible Obsidian fitness logs; archive monthly Obsidian vault items from Area/Projects to Archive (with attachments); audit current branch changes for AGENTS.md conformance and auto-fix violations; clean up stale Codex/ChatGPT desktop state (dead project picker entries, invalid env refs, obsolete worktrees); refine an aichat role prompt (committer, pr-writer, etc.) based on output feedback; or translate text into Taiwan Traditional Chinese for a non-technical 70-year-old parent ("for my mum/dad", "繁體中文", "正體中文").
---

# personal (router)

Progressive-disclosure router for personal-life tasks and tools. The actual instructions live in `nested/<task>/SKILL.md` files. When the task matches one of the bullets below, Read that nested SKILL.md and follow its instructions exactly.

## Dispatch table

- **Workout / gym log → Dataview-compatible Obsidian fitness log** → Read `nested/convert-workout-journal/SKILL.md`.
- **Archive monthly Obsidian vault items** from Area/ and Projects/ to Archive/ (handling attachments) → Read `nested/archive-obsidian-vault/SKILL.md`.
- **Audit branch changes against AGENTS.md** (write report, auto-fix conformance violations) → Read `nested/check-agent-standards/SKILL.md`.
- **Stale Codex/ChatGPT desktop state cleanup** (dead project picker entries, invalid env refs, obsolete worktree pairings) → Read `nested/codex-app-cleanup/SKILL.md`.
- **Refine an aichat role prompt** (committer, pr-writer, etc.) based on output-quality feedback → Read `nested/refine-aichat-role/SKILL.md`.
- **Translate to Taiwan Traditional Chinese** for a non-technical 70-year-old parent / "for my mum/dad" / 繁體中文 / 正體中文 → Read `nested/translate-to-taiwan-chinese/SKILL.md`.

If the request matches more than one, pick the most specific match. If none match cleanly, ask the user which task they want.
