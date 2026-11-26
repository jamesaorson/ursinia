# Greek Source Bible (GSB): agent instructions

Read this whole file before doing any GSB work. It is the standing record of
what the project is, what the owner has decided, and how work is done. The
project runs over many weeks and sessions; you have no memory of earlier ones
except what is written here, in `bd` (beads), and in the files this points to.

## What this is

A new English Bible translated only from Greek, published at
`/bible/versions/gsb/` on this site:

- **Old Testament** from the Septuagint (Swete's edition, our own
  transcription).
- **New Testament** from Nestle 1904, with the longer readings of the Textus
  Receptus (Scrivener 1894) restored and visibly marked.
- One consistent vocabulary across both testaments, so a New Testament
  quotation of the Septuagint matches its source in English wherever the Greek
  matches, and differs where the Greek differs.
- The Greek is shown beside the English verse by verse, each English word
  traceable to its Greek word, and every translation decision recorded on the
  page.

Tracking epic: `ursinia-vff` (`bd show ursinia-vff`, `bd list --parent
ursinia-vff`). Use `bd` for all task tracking, as the root `AGENTS.md` says.

## Rules the owner has set (do not relitigate)

1. **Public domain only.** Every input and everything we publish is public
   domain or CC0, with zero attribution requirements. No CC BY, CC BY-SA, GPL
   or non-commercial data, not even as a lookup table or proofreading aid. The
   owner holds that restrictive licensing of Scripture and its tools is sinful
   (see <https://copy.church/>). Before adding any source, verify its
   public-domain/CC0 statement and quote it in `gsb/sources/<name>/README.md`.
   Rejected for license: Rahlfs/CCAT data in any form, eliranwong's Swete
   (GPL claim), First1KGreek/OGL (CC BY-SA), CNTR SR/KJTR, SBLGNT, MorphGNT,
   STEPBible TAGNT/TBESG, Open Scriptures lemma lists and Strong's, Perseus
   LSJ, Morpheus, NETS, Lexham.
2. **LXX text is our own transcription of Swete** from archive.org scans, book
   by book. No LXX book is rendered until we have transcribed it. No
   placeholder text from Brenton or anyone else.
3. **NT text:** Nestle 1904 base. Words the Textus Receptus has as a pure
   addition are restored and flagged `tr` (Comma Johanneum, Acts 8:37, etc.).
   Where the two differ by substitution or word order, the base stands. Every
   difference is in `gsb/reports/nt-variants.tsv` for review when that chapter
   is translated.
4. **Book order:** conventional Septuagint (Rahlfs-edition) order for the OT,
   then the usual NT order. See `gsb/books.tsv`.
5. **Deuterocanon:** all LXX books are transcribed and rendered, flagged
   deuterocanonical. Translate the 39 protocanonical books first (with the
   Greek additions inside Esther and Daniel), then the NT, and the
   deuterocanon in a final pass.
5a. **No Enoch.** Swete prints Greek fragments of 1 Enoch at the end of his
    third volume. The owner does not want them: do not transcribe or list
    them. (Book number 59 is therefore unused.)
6. **Daniel:** the Old Greek is the authoritative text. Theodotion is shown
   for comparison only (role `comparison` in `books.tsv`). Same for Susanna,
   Bel, and the second Tobit text.
7. **Verse numbering:** common numbering (the numbers Swete prints in
   parentheses in the margin where his own differ). Swete's own numbers are
   kept in the page files.
8. **Proper names:** traditional English forms (Joshua, Isaiah, Moses, Eve),
   the same in both testaments. The Greek form is visible on hover.
9. **Two English layers per verse:**
   - `literal` (hyper-literal), done first:
     - English word order changed only as far as grammar requires.
     - One English gloss per Greek lemma per sense, enforced by script against
       `gsb/lexicon/glosses.scm`.
     - Aspect rendered consistently: imperfect "was X-ing", aorist simple
       past, perfect "has X-ed", historical present kept present.
     - Particles (δέ, καί, γάρ, μέν) always rendered.
     - Every supplied word in [brackets], including articles the Greek lacks:
       "In [the] beginning".
   - `readable` (essentially literal, ESV/NASB register), derived from the
     literal layer.
   - **The readable layer uses words people understand today** (owner,
     2026-11-26). Words that are no longer naturally understood, or that
     now carry misleading associations, are replaced with clear modern
     English there: not "was being borne" (Gen 1:2 reads "was moving").
     The literal layer may keep the stricter gloss. "Firmament" stays in
     both layers for now: the owner dislikes its flat-earth associations
     but rejected "vault" and has not chosen a replacement; do not
     replace it without asking. The words to avoid
     are listed in `gsb/lexicon/readable-avoid.scm` and enforced by
     `make gsb/lint`; add to that list whenever the owner rejects a word.
   - **Both layers keep the source's ambiguity** (owner, 2026-11-26). Where
     the Greek leaves a referent open, the English leaves it open: never
     swap a pronoun for a name, a demonstrative for a personal pronoun, or
     one pronoun for a clearer one. John 1:2 οὗτος is "This one", not "He"
     and not "the Word". If the referent is worth discussing, say so in a
     note, not in the text.

   Whether the readable layer is written with each chapter or in a later pass
   is to be decided after the Genesis 1-3 pilot (`ursinia-vff.4`).
10. **Workflow:** the agent drafts a chapter with its decision notes, marked
    `draft`; the owner reviews and overrules; only the owner's review makes a
    verse `reviewed`. Never mark your own draft reviewed.
11. **Name:** Greek Source Bible, GSB.
12. **Be upfront on the page** about limits: Swete essentially follows one
    manuscript (Vaticanus); the work is drafted with AI assistance and
    reviewed by the owner. The approved "Why do this?" wording lives in
    `scripts/gsb-site.scm`; do not reword it without the owner.
13. **Language:** Guile Scheme for all repo tooling (the owner strongly
    prefers it; small POSIX sh wrappers are fine). No Python in the repo.
14. **Git:** do not commit or push unless the owner asks. When committing, use
    `-s`; no AI attribution or session links.

## How to work

- **Write code to enforce standards.** When a rule can be checked by a script,
  add it to the checker (`scripts/lib/gsb-translation.scm`, run by
  `make gsb/lint`) with a test, instead of relying on care. A rule that lives
  only in prose will be broken by a later session.
- **Record decisions where they are used.**
  - A word choice goes in `gsb/lexicon/glosses.scm` with its `why`.
  - A verse or chapter choice goes in a `(note ...)` in the translation file;
    it renders in the collapsible notes on the page.
  - A project-level decision by the owner goes in this file under the rules
    above, and in `bd remember`.
- **Take notes liberally.** Put findings, open questions and handoff state in
  the relevant bead (`bd update <id> --append-notes "..."`). File a bead for
  anything left undone.
- **Make skills for repeated tasks.** When you find yourself doing a
  multi-step task a second time, write it up as a skill in
  `.claude/skills/<name>/SKILL.md` (mirrored for other agents under
  `.agents/skills/`), precise enough for a fresh agent to follow with no other
  context. Existing: `gsb-transcribe` (transcribing Swete pages).
- **Prefer subagents for execution**, briefed with this file. Transcription
  runs about 5 pages per fresh agent context.
- **Report honestly.** Say what was verified and what was not. Ambiguous print
  or an uncertain rendering is recorded as such, never guessed silently.

## Layout

| Path | What |
|---|---|
| `gsb/README.md` | Greek data formats (authoritative for columns and flags) |
| `gsb/books.tsv` | Ordered book list: id, names, testament, deuterocanonical, role |
| `gsb/sources/` | Pinned public-domain sources, each with a license README |
| `gsb/sources/swete/` | Our Swete transcription: `pages/` is the source of truth; `NN-<id>.tsv` verse tables are generated |
| `gsb/greek/NN-<id>.tsv` | Generated, committed: one row per Greek word (`ref n pre word post lemma strong morph flags`); a word is addressed as `<ref>#<n>` |
| `gsb/lexicon/strongs.tsv` | Generated: Strong's number, lemma, gloss, definition |
| `gsb/lexicon/glosses.scm` | Our concordance: lemma, senses, gloss, reasoning |
| `gsb/translation/NN-<id>/CCC.scm` | The translation, one file per chapter; format in `gsb/translation/README.md` |
| `gsb/reports/` | Generated: NT variants, LXX lemma coverage, unresolved forms |
| `scripts/gsb-*.{sh,scm}`, `scripts/lib/gsb*.scm` | All tooling |
| `assets/bible/gsb/` | Page CSS and JS |
| `wwwroot/bible/versions/gsb/` | Generated site and public dataset (gitignored) |

## Commands

```sh
make gsb/fetch   # download pinned sources
make gsb         # rebuild gsb/greek, reports, lexicon (about 1-2 minutes)
make gsb/check   # fail if committed generated data is stale
make gsb/lint    # check translation files and concordance (also run by make test)
make gsb/uses LEMMA=ἀρχή  # every use of a lemma with sense and English (after adding a sense)
make gsb/site    # generate the page; make render depends on it
make serve       # http://127.0.0.1:8081/bible/versions/gsb/text/
```

## Translating a chapter

Follow `gsb/translation/README.md`. In short: confirm the Greek table exists;
read the chapter's words from `gsb/greek`; for NT chapters read that chapter's
rows in `gsb/reports/nt-variants.tsv` and note each restored or differing
reading; add any new lemma or sense to `glosses.scm` with its `why` before
using it, checking how the lemma is already rendered elsewhere; write the
chapter with every verse `(status draft)`; run `make gsb/lint` until clean and
`make gsb/site`; summarize the decisions for the owner.

## Known gaps in the open resources (why some things are blank)

- No public-domain Septuagint text with lemmas or Strong's numbers exists.
  Ours gets them only for forms that also occur in the CC0 New Testament data
  (about 92% of words in Genesis 1-3). The rest must be lemmatized as our own
  work while translating: use the `(N sense "lemma")` form in the translation
  file.
- Strong's numbers stop at G5624 and cover New Testament vocabulary only.
  LXX-only words have no number and no outbound lexicon links.
- No public-domain digital text of Joshua A / Judges A (Alexandrinus); Swete
  prints the Vaticanus form.
- No accented public-domain Textus Receptus: restored TR words take accents
  from Robinson-Pierpont; the leftovers are in `gsb/reports/nt-unaccented.tsv`
  and need accenting by hand. Whole verses restored from the TR have no
  punctuation yet.
- The Göttingen critical Septuagint is copyrighted, so our base is less
  critical than NETS's.

The owner wants these gaps written up publicly and our data offered as an open
dataset (`ursinia-vff.5`).
