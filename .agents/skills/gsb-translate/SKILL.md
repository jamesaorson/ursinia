---
name: gsb-translate
description: Extend the Greek Source Bible's scripted hyper-literal Old Testament (gsb/literal/) for a chapter range of one book - analyze the Septuagint word forms the generator does not know yet, add concordance entries, generate the chapters, and review them verse by verse, fixing only data (form rows, gloss fields, overrides). Use when asked to "translate", "analyze forms for", "generate" or "review" Septuagint chapters for the GSB (e.g. "follow the gsb-translate skill for Genesis chapters 5-6").
---

# Extending the scripted literal layer

The full procedure lives in one place so it cannot drift: read
`.claude/skills/gsb-translate/SKILL.md` (repository root) and follow it exactly.

In short: read `gsb/AGENTS.md` and `gsb/literal/README.md`; per chapter range
`./scripts/gsb-literal.sh todo <book> <chapters>`, add form rows to
`gsb/literal/forms/NN-<id>.tsv` and entries to `gsb/lexicon/glosses/`,
`generate`, `check`, `show --greek`, fix by form row / gloss field / override,
never by editing output. Only your own Greek and the repo's public-domain
data are sources.
