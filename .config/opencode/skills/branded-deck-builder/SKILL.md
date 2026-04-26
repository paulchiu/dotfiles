---
name: branded-deck-builder
description: Create polished branded decks, presentation slides, bento promo slides, and short shareable presentation videos in the me&u engineering visual style. Use when asked to make or modify a branded deck, PowerPoint, Google Slides-inspired presentation, executive/update deck, bento summary slide, Spotify Wrapped/Rewind-style animation, or team-shareable promo asset using the referenced me&u brand colors, typography, frosted tiles, and diagonal-background style.
---

# Branded Deck Builder

## Overview

Use this skill to turn rough notes, metrics, diffs, docs, or screenshots into a branded presentation artifact. Prefer source-linked brand references and reusable design tokens over hardcoded local artifact paths.

## Workflow

1. Clarify the deliverable only if it is genuinely ambiguous: deck, single promo slide, PNG, PPTX, animated MP4, or a bundle.
2. Gather brand context from user-provided links, Google Drive/Slides, Notion, screenshots, or existing files. If none are accessible, use the embedded tokens in [brand-system.md](references/brand-system.md).
3. For PPTX/deck work, use the `presentations` skill and render each slide for visual QA before handing off.
4. For animation/video work, build deterministic HTML/canvas/Python frames, export H.264 MP4, and create a poster plus contact sheet.
5. Keep artifact paths user-directed. If the user asks for sandbox output, create a dated folder under `~/dev/sandbox`; otherwise use the project or destination they specify.

## Brand References

Read [brand-system.md](references/brand-system.md) when you need concrete colors, typography, bento tile rules, chart contrast rules, or animation patterns.

When tools are available, consult these source references before relying on the embedded summary:

- Notion color/reference board: `https://www.notion.so/meandu/d530f2871cdc47f28c910ef4bfb07bea?v=7f03b3638dff4142a2ea5655811ddbe1`
- Google Slides reference deck: `https://docs.google.com/presentation/d/1JYo-7I_e3ULw12Z4mstwFkBc-grMq6V6J5uIIE-d5wY/edit?slide=id.p#slide=id.p`
- Frosted tile reference slide: `https://docs.google.com/presentation/d/1JYo-7I_e3ULw12Z4mstwFkBc-grMq6V6J5uIIE-d5wY/edit?slide=id.g3c4f2c75670_0_19#slide=id.g3c4f2c75670_0_19`
- Font/style reference slide: `https://docs.google.com/presentation/d/1JYo-7I_e3ULw12Z4mstwFkBc-grMq6V6J5uIIE-d5wY/edit?slide=id.g3c6d0725964_4_166#slide=id.g3c6d0725964_4_166`

## Content Treatment

- Lead with the key outcome, not process narration.
- Convert raw metrics into audience-readable deltas. For values greater than 10, prefer a percentage as the main hero number when a percentage is meaningful; include the raw count in smaller supporting text.
- Use short labels on cards and charts. Put nuance in speaker notes, detailed docs, or supporting captions.
- For engineering updates, highlight reductions, simplifications, remaining risks, and the next action.

## Visual QA

- Render slides or frames to images and inspect them before finalizing.
- Check contrast anywhere Splice green appears behind content; use dark olive/kale marks, text, or outlines there.
- Verify fonts are installed or provide close fallbacks. Do not fail the task only because a proprietary font is unavailable.
- Confirm exported media opens and is valid. For videos, validate codec, dimensions, duration, frame rate, and pixel format.
- Create shareable outputs: PPTX or PDF for decks, PNG for single slides, MP4 plus poster/contact sheet for animations.
