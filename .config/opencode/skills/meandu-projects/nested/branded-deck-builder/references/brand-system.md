# me&u Branded Presentation System

Use these tokens and patterns when live Notion/Google Slides references are inaccessible. Prefer fresh source references when available.

## Palette

Primary:

- Olive: `#001814` for dark backgrounds, chart marks over bright fields, button text, and high-contrast borders.
- Kale: `#00362F` for secondary dark backgrounds and card depth.
- Splice: `#DBFC45` for the signature bright green accent, hero words, active pills, and positive movement.
- Aioli: `#FFFAF3` for warm white text on dark backgrounds.

Supporting:

- Salmon: `#FFC7C8` for secondary reductions, contrast accents, and warm callouts.
- Sloe: `#9191E9` for transition accents and secondary decorative motion.
- Chilli: `#FE4532` for remaining risk, blockers, or one critical item.

Contrast rules:

- Do not put Splice text, Splice chart marks, or pale green objects directly on a Splice-heavy background.
- On Splice backgrounds, use Olive or Kale for chart bars, chart labels, outlines, and button borders.
- On dark Olive/Kale cards, use Aioli for labels and Splice/Salmon/Chilli only for the emphasized number.

## Typography

Preferred:

- Display: Zalando Sans Expanded Bold or Zalando Sans Expanded. Use for large headings, all-caps labels, buttons, and compact branded words.
- Body and numerals: Plus Jakarta Sans, usually Medium or Bold. Use for stats, labels, support copy, and small captions.

Fallbacks:

- Display fallback: Arial Black, Archivo Expanded, or another wide geometric sans.
- Body fallback: Plus Jakarta Sans from Google Fonts, Inter, Arial, or another clean geometric sans.

Keep letter spacing at `0`. Avoid viewport-scaled font sizes. Use a large display face only for true hero headings or stat numerals.

## Layout Language

- Use 16:9 as the default canvas.
- Build around an Olive/Kale field with a large diagonal Splice band or diagonal dark/green overlays.
- Let the main subject or metric occupy the first viewport. Avoid marketing-style split hero cards.
- Use bento tiles for repeated stats: stable dimensions, rounded corners, dark translucent fill, subtle light outline, and restrained shadow.
- Prefer generous negative space with compact labels over paragraphs.
- Use small rounded pill labels for section eyebrows such as `BIGGEST DROP`, `PRISMA GROWTH`, or `REMAINING WORK`.

## Bento Tiles

Recommended tile treatment at 1920x1080 scale:

- Fill: dark Kale/Olive with roughly 70-92% opacity.
- Outline: warm Aioli at about 55-75% opacity, 2-3 px.
- Radius: 26-54 px depending on tile size.
- Shadow: soft dark Olive shadow, offset down/right, blurred. Keep it visible but not muddy.
- Frosting: use subtle transparency and outline. Avoid heavy simulated glass on very large tiles; it can look uneven. If requested, add only a light top sheen.

Cards should not nest inside other cards. Keep text inside card bounds on mobile and desktop exports.

## Charts And Numbers

- Use dark Olive/Kale bars and labels when the chart sits over Splice.
- Use Splice or Aioli bars only on dark backgrounds.
- If a metric is above 10 and a percentage is meaningful, make the percentage the large number and put the raw count in the detail line. Counts from 1-10 can remain as the main number.
- Examples:
  - `-18%` as hero; `23 fewer direct repositories; 131 -> 108.` as detail.
  - `-12%` as hero; `17 fewer entity-module links; 146 -> 129.` as detail.
  - `+15%` as hero; `37 more Prisma files; 245 -> 282.` as detail.
  - `6` as hero; `modules dropped out` as label.
  - `1` as hero in Chilli; `circular pair remains` as label.

## Buttons And Calls To Action

- Use Splice fill with Olive text for bright CTA pills.
- When the CTA is placed over Splice or another bright area, add a dark Olive border and a soft dark shadow.
- Use display typography for the CTA label. Keep the label short, for example `share with the team`.

## Motion Pattern

For Spotify Wrapped/Rewind-style presentation videos:

- Keep videos short: 12-20 seconds for team sharing.
- Use 1920x1080, 30 fps, H.264, `yuv420p`, and `+faststart`.
- Use one idea per scene: cover, biggest drop, usage reduction, growth, cleanup, remaining work, finale.
- Animate in with eased vertical or horizontal movement. Use diagonal color wipes for transitions.
- Export a poster and contact sheet for quick review.

## Source Links

Consult these if connector access is available:

- Notion color/reference board: `https://www.notion.so/meandu/d530f2871cdc47f28c910ef4bfb07bea?v=7f03b3638dff4142a2ea5655811ddbe1`
- Google Slides reference deck: `https://docs.google.com/presentation/d/1JYo-7I_e3ULw12Z4mstwFkBc-grMq6V6J5uIIE-d5wY/edit?slide=id.p#slide=id.p`
- Frosted tile reference slide: `https://docs.google.com/presentation/d/1JYo-7I_e3ULw12Z4mstwFkBc-grMq6V6J5uIIE-d5wY/edit?slide=id.g3c4f2c75670_0_19#slide=id.g3c4f2c75670_0_19`
- Font/style reference slide: `https://docs.google.com/presentation/d/1JYo-7I_e3ULw12Z4mstwFkBc-grMq6V6J5uIIE-d5wY/edit?slide=id.g3c6d0725964_4_166#slide=id.g3c6d0725964_4_166`
