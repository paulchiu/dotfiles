---
name: frontend-design
description: "Create distinctive, production-grade frontend interfaces with high design quality. Use when asked to build web components, pages, or apps; generates polished code that avoids generic AI aesthetics."
license: Complete terms in LICENSE.txt
---

Create distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. The user provides requirements: a component, page, app, or interface, possibly with context about purpose, audience, or technical constraints.

## Before coding

Commit to one bold aesthetic direction:

- **Purpose**: What problem does this solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, or something else true to the context.
- **Differentiation**: What is the one thing someone will remember?

Bold maximalism and refined minimalism both work. The key is intentionality, not intensity: choose a clear conceptual direction and execute it with precision. Match implementation complexity to the vision: maximalist designs need elaborate animation and effects; minimalist designs need restraint and careful spacing, typography, and subtle detail.

## Aesthetic guidelines

- **Typography**: Pair a distinctive display font with a refined body font. Avoid generic choices (Arial, Inter, Roboto, system fonts); pick characterful, unexpected fonts.
- **Color**: Commit to a cohesive palette via CSS variables. Dominant colors with sharp accents outperform timid, evenly-distributed palettes. No purple-gradient-on-white cliches.
- **Motion**: One well-orchestrated page load with staggered reveals (animation-delay) beats scattered micro-interactions. Prefer CSS-only for plain HTML; use the Motion library for React when available. Add scroll-triggered effects and hover states that surprise.
- **Composition**: Unexpected layouts: asymmetry, overlap, diagonal flow, grid-breaking elements. Generous negative space or controlled density.
- **Backgrounds and detail**: Build atmosphere and depth instead of flat solid colors: gradient meshes, noise or grain textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors.

Every design should feel genuinely designed for its context, and no two generations should look alike: vary light/dark themes, fonts, and aesthetics, and never converge on common choices (Space Grotesk, for example) across generations.

The output is working, production-grade code (HTML/CSS/JS, React, Vue, etc.): functional, visually striking, cohesive, and meticulously refined. Don't hold back; commit fully to the distinctive vision.
