---
name: personal
description: Router for dad's monthly ANZ money report; PocketSmith API work (transactions, categorisation, budgets, reporting); monthly Obsidian Area/Projects → Archive; translate to Taiwan Traditional Chinese ("for my mum/dad"); rename ebook files; refine aichat role prompts.
---

# personal (router)

Progressive-disclosure router for personal-life tasks and tools. The actual instructions live in `nested/<task>/SKILL.md` files. When the task matches one of the bullets below, Read that nested SKILL.md and follow its instructions exactly.

## Dispatch table

- **Prepare Dad's monthly family money report** from ANZ credit card exports, the prior Excel format, and the current Obsidian journal account details; also "family finances", "ANZ report", "credit card bill email", the recurring Gmail draft for Dad/Mom/Nicole → Read `nested/prepare-dad-money-report/SKILL.md`.
- **PocketSmith API work**: pull or categorise transactions, category rules, splits and labels, budget vs actual reporting, savings rate, spending by category or payee, uncategorised transactions, or setting budgets via scenario events → Read `nested/pocketsmith/SKILL.md`.
- **Archive monthly Obsidian vault items** from `Area/` and `Projects/` to `Archive/` with year-level grouping (handling drawing attachments and journal files) → Read `nested/archive-obsidian-vault/SKILL.md`.
- **Translate to Taiwan Traditional Chinese** for a non-technical 70-year-old parent / "for my mum/dad" / 繁體中文 / 正體中文 → Read `nested/translate-to-taiwan-chinese/SKILL.md`.
- **Rename ebook files** (epub or pdf) to the `Title - Subtitle. LastName, I. Year.ext` convention; also "organize" or "clean up" ebook filenames → Read `nested/ebook-naming/SKILL.md`.
- **Refine an aichat role prompt** (committer, pr-writer, etc.) based on output-quality feedback → Read `nested/refine-aichat-role/SKILL.md`.

If the request matches more than one, pick the most specific match. If none match cleanly, ask the user which task they want.
