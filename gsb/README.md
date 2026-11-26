# Greek Source Bible: Greek data

The Greek text behind the Greek Source Bible (GSB), one row per word. It is
built from public-domain and CC0 sources only:

| source                                  | used for                                                  |
| --------------------------------------- | --------------------------------------------------------- |
| `sources/swete/` (our transcription)    | LXX text (Swete)                                          |
| `sources/nestle1904/` (CC0 / PD)        | NT base text, lemmas, Strong's numbers, parsing           |
| `sources/tr/` (PD)                      | Textus Receptus (Scrivener 1894) longer readings          |
| `sources/rp/` (PD / CC0)                | accents for restored TR words (Robinson-Pierpont)         |
| `sources/dodson/`, `sources/strongs/`   | `lexicon/strongs.tsv` glosses and definitions             |

Each `sources/*/README.md` gives the upstream URL, pinned commit and the
upstream public-domain or CC0 statement.

## Commands

```sh
make gsb/fetch   # download the pinned sources (checksums in sources/SHA256SUMS)
make gsb         # rebuild greek/, reports/ and lexicon/ (unchanged files are left alone)
make gsb/check   # fail if the committed output is stale
make test        # includes scripts/lib/test/gsb/test.scm
```

Code: `scripts/gsb-fetch.sh`, `scripts/gsb-build.sh` -> `scripts/gsb-build.scm`,
shared helpers in `scripts/lib/gsb.scm`.

## `books.tsv`

Book order, ids and canon flags. Columns: `nn` (file prefix), `id`, `english`,
`greek`, `testament` (`OT`/`NT`), `deuterocanonical` (`yes` for books outside
the 39-book Protestant OT; Greek additions inside Esther and Daniel stay in
those books), `role` (`main`; `comparison` for Theodotion's Susanna, Daniel and
Bel and Sinaiticus Tobit, which follow their main text), `source`, `notes`.

## `greek/NN-<id>.tsv`

UTF-8, NFC, tab-separated, header row, one row per Greek word in text order.

| column   | meaning                                                                                        |
| -------- | ---------------------------------------------------------------------------------------------- |
| `ref`    | `<id>.<chapter>.<verse>`; LXX verses use the common numbering Swete prints in parentheses (rule 7), including lettered verses and half verses (`3kgdms.2.35a`, `gen.31.48a`); rows keep Swete's printed order, so a transposed verse comes out of numerical order (`gen.35.21` before `gen.35.16`) |
| `n`      | 1-based word number within the verse                                                           |
| `pre`    | punctuation before the word (`(`, `[[`, `“`)                                                    |
| `word`   | the word, NFC; elision marks are written U+2019 (`κατ’`)                                       |
| `post`   | punctuation after the word (`,` `.` `·` `;` `)` …)                                              |
| `lemma`  | dictionary form, or empty                                                                       |
| `strong` | `G1`-`G5624`, or empty                                                                          |
| `morph`  | Robinson parsing code (NT only), e.g. `V-PAI-3S`                                               |
| `flags`  | comma-separated, see below                                                                      |

A word is addressed as `<ref>#<n>` (`john.1.1#3`). The pair is stable as long
as the source text of that verse does not change; restored TR words are
numbered in place, so they shift the numbers of the base words after them.

Joining `pre word post` with spaces between words gives the printed text.

### Flags

| flag       | meaning                                                                                                   |
| ---------- | --------------------------------------------------------------------------------------------------------- |
| `tr`       | NT: a longer Textus Receptus reading restored into the Nestle 1904 base                                   |
| `tr-verse` | NT: the whole verse is absent from Nestle 1904 and comes from the TR (also `tr`)                          |
| `accent?`  | NT: restored TR word whose accents could not be recovered; written unaccented                            |
| `punct`    | NT: restored TR word that received punctuation moved or copied from the base word before the insertion  |
| `decap`    | LXX: Swete's unaccented capitals (`ΕΝ ΑΡΧΗ`) restored to a normal accented form                           |
| `caps`     | LXX: still in Swete's capitals; no unambiguous accented form was found                                   |
| `lemma?`   | LXX: lemma guessed (form maps to several lemmas, or matched only without accents)                       |
| `siglum`   | LXX: an editorial siglum (U+2E00-U+2E0F) was removed here                                                 |
| `bracket`  | LXX: square brackets were removed from this word                                                          |

## NT merge rule

Base: Nestle 1904. Each verse is compared with Scrivener's TR (the `B` reading
of Robinson's `| A | B |` variants) by a weighted LCS over accent-stripped,
lowercased letters; movable nu (`εἰσίν/εἰσί`), `οὕτως/οὕτω`, `ἄχρις/μέχρις`
and elision are folded so spelling noise is not a variant; equal letters plus
equal Strong's number pair most strongly, then equal letters, then equal
Strong's number with the same first two letters and similar length
(`Δαυείδ/δαβιδ`).

- A run that only the TR has is restored (flag `tr`), unless it repeats words
  the base has elsewhere in the verse (word order), matches base words the TR
  lacks in a neighboring verse (verse-boundary shift), or sits next to a base
  word of the same part of speech that the TR lacks (a split substitution).
- Substitutions and word-order differences keep the base.
- Verses missing from Nestle 1904 come wholesale from the TR (`tr-verse`)
  unless their words sit in a neighboring Nestle verse.
- Restored words take lemma from Nestle's most frequent lemma for that Strong's
  number, Strong's and parsing from the TR, and accents from: the same RP verse
  (one matching spelling, consistent with Nestle's spellings for that Strong's
  number), the neighboring RP verses, Nestle's single spelling for those letters
  and Strong's number (accent differences caused by enclitics ignored), or the
  single Nestle/RP spelling for those letters. Otherwise `accent?`.

Every difference is listed in `reports/nt-variants.tsv` for footnoting.

## LXX

`sources/swete/NN-<id>.tsv` is read verse by verse, tokenized on whitespace,
and punctuation split off. Capitals are restored only when the
accent-stripped form has exactly one accented spelling (ignoring case and
grave/acute) across the transcribed LXX, Nestle 1904 and RP. Lemmas and
Strong's numbers come only from a form table built from Nestle 1904 (and TR
forms through their Strong's numbers): exact accented form first, then
accent-stripped form when it maps to exactly one lemma (`lemma?`). The rest
stays blank for our own lemmatization later. Books without a transcription
file are listed as "not yet transcribed" in `reports/lxx-coverage.tsv`.

## Reports

- `reports/nt-variants.tsv` — `ref, kind, nestle1904, tr`; kinds: `insert`,
  `verse` (restored); `subst`, `subst-split`, `order`, `tr-omits`, `moved`,
  `moved-verse` (base kept).
- `reports/nt-unaccented.tsv` — restored words left unaccented, to accent by hand.
- `reports/lxx-coverage.tsv`, `reports/lxx-unmatched-forms.tsv` (top 200),
  `reports/lxx-capitals.tsv`.

## `lexicon/strongs.tsv`

`strong, lemma` (Nestle 1904's lemma for the number, else Strong's headword),
`strongs_headword`, `gloss` (Dodson, brief), `definition` (Dodson's longer
definition, else Strong's), `definition_source`.
