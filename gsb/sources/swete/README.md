# Swete, *The Old Testament in Greek* — our transcription

Our own transcription of the main text of H. B. Swete's edition of the
Septuagint, made directly from public-domain page scans. No third-party digital
text is a source of any character here.

Status: in production. `./scripts/gsb-swete.sh status gen` shows which leaves
are done. The procedure is `.claude/skills/gsb-transcribe/SKILL.md`.

## Files

| File | What |
|---|---|
| `pages/<book>/v<vol>-<leaf>.txt` | The transcription itself, one file per scan leaf: one printed line per text line (see *Page format*). The source of truth. |
| `pages/<book>/v<vol>-<leaf>.decisions.tsv` | That leaf's decision log (same columns as `decisions.tsv`). |
| `leaves.tsv` | Each book's volume, scan and leaf range (`step` 2 for Daniel's facing texts). |
| `NN-<id>.tsv` | One row per verse (`chapter<TAB>verse<TAB>text`) in the **common** numbering, in Swete's printed order, generated. `verse` is a number or a half verse (`48a`). |
| `decisions.tsv` | All decision logs, generated: every token where the readings disagreed or a mandatory check applied, the readings, what was chosen and why. |
| `provenance.tsv` | Per book and Swete chapter: scan, leaves, printed pages, dates, method versions; generated. |

Every leaf's files are written only by the agent working on that leaf, so many
can work at once. The generated files come from the done leaves only, from each
book's first leaf up to the first leaf not yet done:

```sh
./scripts/gsb-swete.sh merge
```

## Scans and why they are public domain

| Vol. | Contents | archive.org identifier | Edition |
|---|---|---|---|
| I | Genesis – 4 Kingdoms | `theoldtestamenti00unknuoft` | 4th ed. 1909, reprinted 1925 |
| II | 1 Chronicles – Tobit | `oldtestamenting02swet` | 3rd ed. 1907 |
| III | Hosea – 4 Maccabees (incl. Daniel) | `oldtestgreek00unknuoft` | 4th ed. 1912, reprinted 1930 |

All three were published in 1930 or earlier, so they are in the public domain in
the United States. Swete died in 1917, so the edition is also out of copyright
wherever the term is life plus 70 (or even 100) years. The scans are
mechanical reproductions and add no copyright. We record only identifiers and
leaf numbers here; the images and OCR layers stay out of the repo
(`./scripts/gsb-swete-fetch.sh` puts them in `~/.cache/gsb-swete`).

## Transcription conventions

- **Main text only.** Running heads, the critical apparatus, marginal chapter
  and verse numbers and the marginal manuscript sigla are left out.
- **Spelling, accents, breathings, iota subscripts and capitals exactly as
  printed**, including Swete's habits: the acute before a capitalized
  quotation (`εἶπεν ὁ θεός Γενηθήτω`), unaccented capitals in the chapter-opening
  words (`ΕΝ ΑΡΧΗ`, `ΕΠΙ`, `ΕΝ`), lowercase after a period, and misprints
  (`ἐσθόντων`, Dan. Th. 1:13; `Ἑιὼχ`, Gen 5:19). Nothing is normalized.
- **Characters** (UTF-8, NFC): ano teleia `·` (U+00B7, what NFC makes of
  U+0387), question mark `;` (U+003B, likewise from U+037E), elision mark `᾽`
  (U+1FBD, e.g. `καθ᾽`).
- **Square brackets are kept.** In Genesis Swete prints the text of Codex
  Alexandrinus and brackets the letters that have perished in it
  (apparatus: "quae uncis incl sunt perier in A"), e.g. `πετόμεν[α]`. Brackets
  can split a word (`κτ[ήνη`) or span verses.
- **`¶` and `§` are kept in `pages/` and dropped from the verse tables.** They
  mark where a fragmentary witness named in the margin stops or resumes; they
  are apparatus, not text.
- **Hyphenated line breaks** are joined in the tables (`Γενη-` + `θήτω` →
  `Γενηθήτω`), also across a page break; `pages/` keeps the printed lines.
- **Paragraphs and poetry** are recorded in `pages/` (`{P}`, `{S}`) and not in
  the tables.
- **Verse numbers.** The tables use the **common** numbering: where Swete's own
  numbering differs he prints the common number in parentheses in the margin,
  e.g. `(25)(II)` and `(1)(III)` beside his III 1. The page files keep Swete's
  own superscript numbers (`{C3}{1}`) and record the common one beside them
  (`{=2:25}`, `{=3:1}`). So far: Swete's Gen 3:1 = common 2:25 + 3:1, Swete's
  Gen 6:1 = common 5:32 + 6:1. Daniel 1 has no parenthesized numbers in either
  text. `provenance.tsv` counts Swete's chapters.
- **Where the Septuagint orders or divides verses differently**, the table
  follows Swete's print, not numerical order, and each common verse appears
  once:
  - *Transposed verses*: Gen 35:21 stands before 35:16 (leaf 99: Swete prints
    `(21) 16`, then `(16)`, then `(22) 21`), so the table runs 35:15, 35:21,
    35:16, 35:17, ... 35:20, 35:22.
  - *Half verses*: Swete's margin divides Gen 31:48, 31:52 and 31:50 into
    `a`/`b` parts printed apart (leaf 92: `(48 a)`, `(51)`, `(52 a)`, `(48 b)`,
    `(50 a)`, `52 b`); the table has verses `48a`, `47`, `51`, `52a`, `48b`, `49`,
    `50a`, `52b` in that order. No `50b` is printed.
  - *A gap in Swete's own numbers*: he has no 31:51 (his 48 is common 51); the
    page file marks the printed skip as `{52!}`.
  - *Numbers in the text*: a parenthesized common number printed inside a line
    (Gen 15:21, 19:4, 22:4, 22:16, 23:5–6, 23:14–15, 24:19, 24:25–26, 31:54,
    47:6) is a `{=c:v}` at that point. At Gen 49:24 (leaf 132) Swete prints
    `(24)` before παρὰ θεοῦ τοῦ πατρός σου, four lines after his own 24: a
    misprint for `(25)`, encoded `{=49:25}`, with the printed form in a comment
    in the page file and a flag row in its decisions.
  - Swete's 31:55 is common 32:1 and his chapter 32 runs one behind the
    common (Hebrew) numbering throughout, so Genesis 31 has 54 verses and 32
    has 33 in the table, as in Hebrew numbering (English Bibles: 55 and 32).
- **Editorial marks** in the text, such as Swete's asterisk at Gen 37:1 tied to
  a note, are apparatus and are left out.
- **Daniel** is printed twice: the Old Greek (Chigi MS 87, `ΔΑΝΙΗΛ ΚΑΤΑ ΤΟΥΣ Ο'`)
  on the even (left) leaves, book `dan`, and Theodotion (`ΚΑΤΑ ΘΕΟΔΟΤΙΩΝΑ`) on
  the facing odd leaves, book `dan-th`. Each is a separate table.

### Page format

```
# theoldtestamenti00unknuoft leaf 0036 (printed page 4)
# box 230 2680 185 1960
# done 2026-11-25 swete-pilot-1
καὶ ἔσονται οἱ δύο εἰς σάρκα μίαν. {C3}{1}{=2:25}καὶ ἦσαν οἱ δύο γυμνοί, ὅ τε
Ἀδὰμ καὶ ἡ γυνὴ αὐτοῦ, καὶ οὐκ ᾐσχύνοντο.
{P}{=3:1}Ὁ δὲ ὄφις ἦν φρονιμώτατος πάντων τῶν θηρίων τῶν ἐπὶ τῆς γῆς
```

Header lines (written by the tools): scan and leaf, the main-text box in page
pixels (`y0 y1 x0 x1`), and the done stamp (date, method). Then one printed line
per line (`#` lines below the header are comments). Markers:

| Mark | Meaning |
|---|---|
| `{C3}` | Swete's chapter 3 starts |
| `{7}` | Swete's verse 7 starts (where his superscript stands); the common reference becomes chapter:7 |
| `{=2:25}` | the common reference from here until Swete's next `{n}` (his parenthesized number, in the margin or the text); may go backwards, but each common verse is given once per book |
| `{=31:48a}` | the same for a half verse (Swete's `(48 a)`) |
| `{52!}` | Swete's verse 52, where his own numbering skips (as printed); an unmarked skip fails |
| `{P}` | the line starts an indented paragraph |
| `{S}` | the line is a line of poetry |
| `¶` `§` | witness marks printed in the text |

Lines starting with `#` are comments. A line ending in `-` continues on the next
line, or on the next leaf's first line. Files are read in leaf order; a page
that starts mid-verse continues it. `./scripts/gsb-swete-verses.sh PAGE-DIR`
previews a table from every page in a directory.

## Method (version `swete-2`)

Three readings of each page, all from the page image, collated token by token;
OCR is a list of places to look again, not a vote.

1. **Fetch** (`./scripts/gsb-swete-fetch.sh VOL LEAF...`; `doctor` checks curl,
   ffmpeg, Tesseract, the pinned `grc` model and Guile): the page image,
   archive.org's hOCR for the leaf (**reading A**) and a fresh Tesseract 5 pass
   with `tessdata_best/grc` (**reading B**), all in `~/.cache/gsb-swete`.
2. **Box**: the main-text box per leaf, excluding running head, margins and
   apparatus (suggested from the OCR, checked by eye; the suggestion errs
   loose on the left, where a clipped letter hurts the OCR more than a
   sliver of margin).
3. **Reading C**: the transcriber reads the image in strips of five lines at
   full resolution and writes the page file.
4. **Collate** (`./scripts/gsb-swete.sh collate`): A and B are cut to the box
   (words whose left edge is in it; lines with too little Greek dropped; lines
   overlapping by more than half merged), normalized (spacing breathings before
   capitals, elision marks) and aligned with C by a weighted LCS. Differences
   of a known OCR kind are settled by class: R0 OCR lost the word, R1 verse
   superscript fused into the word, R2 ano teleia read as `" : '` or elision
   mark dropped, R3 junk appended, R4 brackets dropped, R5 Latin look-alike
   letters, R6 the other OCR agrees with C (letters differ), R7 the other OCR
   agrees with C (OCR only lacks diacritics). Everything else, and three
   mandatory checks where both OCRs fail together (H1 breathing on a capital or
   capitalized diphthong, H2 accent before an enclitic, H3 acute/grave before a
   capitalized word), is cropped from the image at 3× and settled by eye. The
   decision file is reconciled on every run: settled decisions follow their
   word through line shifts and box changes, stale TODO rows are dropped, and
   no settled decision is ever dropped. A lone OCR `;` (Swete's thin space
   before the question mark) is joined to its word.
5. **Validate** (`done`, `status`): markers, NFC, characters, brackets, Swete's
   own verse order (skips only where marked `{n!}`), each common verse given
   once per book, every decision settled.

Version `swete-pilot-1` (Genesis leaves 33–37, Daniel 522–527) did steps 1–4 by
hand with throwaway scripts; its measured accuracy, cost and hazards are in the
beads issue `ursinia-vff.6`.

## License

To the extent possible under law, the authors of this transcription have
waived all copyright and related or neighboring rights to it under CC0 1.0
Universal (<https://creativecommons.org/publicdomain/zero/1.0/>). No
attribution is required. Swete's printed text is itself in the public domain.
