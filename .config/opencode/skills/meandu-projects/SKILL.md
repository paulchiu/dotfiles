---
name: meandu-projects
description: Router for me&u project work. Use when asked to build branded decks, presentations, bento slides, or Spotify Wrapped-style animations in the me&u engineering visual style; review candidate resumes or interview transcripts and draft hiring feedback; or generate Obsidian-style implementation guidance docs for technical issues, bug fixes, or features.
---

# meandu-projects (router)

Progressive-disclosure router. The actual instructions live in `nested/<task>/SKILL.md` files. When the task matches one of the bullets below, Read that nested SKILL.md and follow its instructions exactly.

## Dispatch table

- **Branded deck / presentation / bento slide / Spotify Wrapped-style animation** in the me&u engineering visual style → Read `nested/branded-deck-builder/SKILL.md`.
- **Resume review, interview transcript analysis, recruiter feedback, hiring decision draft** → Read `nested/reviewing-candidates/SKILL.md`.
- **Obsidian-style implementation guidance doc with file refs, code locations, and step-by-step plans for a technical issue / bug fix / feature** → Read `nested/implementation-guidance-generator/SKILL.md`.

If the user's request matches more than one, pick the most specific match. If none match cleanly, ask the user which task they want.
