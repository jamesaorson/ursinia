# AGENTS.md

All `.md` files in this `scripture-readings/` folder (and its chapter subfolders) should follow the same structure.

## Required Folder and File Naming

1. Chapter subfolders should follow this pattern:
1. `<book-number>-<book-name>`
1. Use a two-digit, zero-padded canonical book number (for example, `08` for Ruth).
1. Use lowercase book names with hyphens between words.
1. Example: `08-ruth`.
1. Reading files in those folders should follow this pattern:
1. `<book-name>-<chapter>.md`
1. Use lowercase book names with hyphens between words.
1. Use Arabic numerals for chapter numbers.
1. Zero-pad chapter numbers based on the total chapter count of that biblical book.
   1. The padding width is the number of digits in the book's total chapter count.
   1. Examples:
      1. Ruth has 4 chapters (width 1\): `ruth-1.md`, `ruth-3.md`.
      1. John has 21 chapters (width 2\): `john-01.md`, `john-21.md`.
      1. Psalms has 150 chapters (width 3\): `psalms-001.md`, `psalms-150.md`.
1. If a reading is not a full chapter and instead covers a verse range, use this segment format for the passage part: `<chapter>_<starting-verse>-<ending-verse>`.
1. Examples: `john-18_28-19_16a.md`, `acts-03_01-04_31.md`.

## Required File Structure

1. Start with YAML frontmatter wrapped by `---` lines.
1. Include the `# YYYY-MM-DD` marker line at the top of the frontmatter.
1. Include these keys in this order:
   1. `title`
   1. `date`
   1. `author`
   1. `tags` (as a YAML list)
1. Close frontmatter with `---`.
1. Add a blank line.
1. Write the body content as a numbered outline using Markdown ordered lists (including nested numbered points where needed).

## Frontmatter Template

```yaml
---
title: <Book Chapter - Short Theme>
# YYYY-MM-DD
date: <YYYY-MM-DD>
author: James Orson
tags:
  - <BookName>
---
```

## Content Pattern

- Use theological/exegetical notes in ordered-list outline form.
- Prefer `1.` style numbering for all list levels, consistent with existing Ruth files.
- Keep line wrapping readable for long points.
