---
name: ebook-naming
description: "Rename epub files to match Paul's personal ebook naming convention. Use when asked to rename, organize, or clean up ebook files (epub or pdf). The convention for naming is: Title - Subtitle. LastName, FirstInitial. Year.ext (omit subtitle if none). No publisher, no hash IDs, no Anna's Archive labels."
---

# Ebook Naming

## Convention

Format ebook files as:

```
Title - Subtitle. LastName, FirstInitial. Year.epub
```

### Rules

- **Title**: Capitalize normally (preserve original casing). No trailing punctuation.
- **Subtitle**: After ` - ` (space-hyphen-space) if present. No trailing period in the subtitle (the period after subtitle belongs to the author block).
- **Author block**: After a period and space: `LastName, FirstInitial.` (initial with period). For multiple authors: `LastName, FirstInitial., & LastName, FirstInitial. Year.ext`
- **Year**: After another period and space: four-digit year.
- **Extension**: `.epub` (or `.pdf` etc.)
- **No extras**: Strip publisher names, edition strings, hash IDs, "Anna's Archive", download site labels.

### Examples

| Before | After |
|--------|-------|
| `The Anxious Generation_ How the Great Rewiring of Childhood -- Haidt, Jonathan -- 2024 -- Penguin Publishing Group -- 82bb43d19e4384510bae3c9ca77f4807 -- Anna's Archive.epub` | `The Anxious Generation - How the Great Rewiring of Childhood. Haidt, J. 2024.epub` |
| `Designing Data-Intensive Applications - The Big Ideas Behind Reliable, Scalable, and Maintainable Systems. Kleppmann, M. 2017.epub` | Already correct |
| `The Daily Stoic - 366 Meditations on Wisdom, Perseverance, and the Art of Living. Holiday, R., & Hanselman, S. 2016.epub` | Already correct |
| `Taiwan Travelogue. Yáng, S. 2024.epub` | Already correct |
| `Figuring. Popova, M. 2019.epub` | Already correct |