---
name: gsb-transcribe
description: Transcribe pages of H. B. Swete's Septuagint ("The Old Testament in Greek") from archive.org page scans into gsb/sources/swete/pages/, for the Greek Source Bible. Use when asked to transcribe Swete leaves or pages (e.g. "transcribe Genesis leaves 39-43"), to settle or check a Swete page's decisions, or to see which Swete pages are done or missing.
---

# Transcribing Swete page by page

The full procedure lives in one place so it cannot drift: read
`.claude/skills/gsb-transcribe/SKILL.md` (repository root) and follow it exactly.

In short: `./scripts/gsb-swete-fetch.sh doctor`, then per leaf `fetch`, `box`,
`strips`, write the page file, `collate`, settle every TODO with `decide`
against the zoom sheets, `done`; `./scripts/gsb-swete.sh status <book>` shows
progress. Only the page images are a source; never another digital text.
