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
| `NN-<id>.tsv` | One row per verse (`chapter<TAB>verse<TAB>text`) in the **common** numbering (English chapter division), in Swete's printed order, generated. `verse` is a number, a half verse (`48a`), or several common verses Swete prints as one (`4-5`, `34,36b`). |
| `versification.tsv` | Our own map (CC0) from the Hebrew chapter division Swete's parenthesized numbers follow to the English one, applied by `merge`: `book`, `from` and `to` (a Hebrew `c:v` range within one chapter), `english` (the English `c:v` of `from`). Only the known chapter-boundary differences of the books we have. |
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
  (U+1FBD, e.g. `καθ᾽`), the keraia of a letter numeral `ʹ` (U+02B9, what NFC
  makes of U+0374 GREEK NUMERAL SIGN; allowed only right after the letters:
  `ιβʹ` = 12, Exod 15:27), and the lower keraia of thousands `͵` (U+0375,
  right before its letter: `͵α` = 1000, 2 Esdras 2:37; Swete's stigma prints
  as `ς`, `͵αςʹ` = 1006, 2 Esdras 17:41).
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
  - *Swete's own numbers printed out of order*: Num 6 runs 23, 27, 24, 25, 26
    (leaf 300: verse 27 stands before the blessing) and Num 10 runs 33, 35, 36,
    34 (leaf 310), with no parentheses. Every number that breaks the sequence
    is marked (`{27!}`, `{24!}`; `{35!}`, `{34!}`); the table keeps the printed
    order (6:23, 6:27, 6:24, ...; 10:33, 10:35, 10:36, 10:34).
  - *Numbers in the text*: a parenthesized common number printed inside a line
    (Gen 15:21, 19:4, 22:4, 22:16, 23:5–6, 23:14–15, 24:19, 24:25–26, 31:54,
    47:6) is a `{=c:v}` at that point. At Gen 49:24 (leaf 132) Swete prints
    `(24)` before παρὰ θεοῦ τοῦ πατρός σου, four lines after his own 24: a
    misprint for `(25)`, encoded `{=49:25}`, with the printed form in a comment
    in the page file and a flag row in its decisions.
  - *One Swete verse for several common verses*: the margin prints `(4, 5)`,
    `(19-22)`, `(34, 36)` (Exod 37-38, 40:30-31). The page file writes it as
    printed, `{=37:4-5}`, `{=37:19-22}`, `{=36:34,36}` (ascending); the table
    has one row with verse `4-5`, and each verse in it counts as given.
  - *A common number printed twice* (Exod 25:34, 36:36, 38:20, 39:1, 39:40):
    the two places get the half-verse letters `a` and `b` (`{=25:34a}`,
    `{=25:34b}`; inside a list, `{=36:34,36b}`). These letters are ours, not
    Swete's; the page file says so in a `#` comment.
  - *A Swete verse with no parenthesized number inside a stretch where the
    numbering differs* (Exod 35:13-14, 36:8, 36:26 and others in 35-40): it
    has no counterpart of its own, so it runs on with the common verse before
    it (`{13}{=35:17}`), with a `#` comment and a flag row; left alone it
    would fall back to Swete's own number and clash or mislead. `status`
    warns when such a verse lands in another chapter than the common verse
    before it.
  - *Hebrew and English chapter division*: Swete's parenthesized numbers
    follow the Hebrew. His Gen 31:55 is `(32:1)` and his chapter 32 runs one
    behind; his Exod 8:1-4 is `(7:26-29)` and 8:5-32 is `(8:1-28)`; his
    Exod 22:1 is `(21:37)` and 22:2-31 is `(22:1-30)`. His Lev 6:1-7 is
    `(5:20-26)`, 6:8-30 is `(6:1-23)`, 6:31-40 is `(7:1-10)` and 7:1-28 is
    `(7:11-38)` (Hebrew and English agree on chapter 7). His Num 16:36-50 is
    `(17:1-15)` and 17:1-13 is `(17:16-28)`; his Num 30:1-17 is the Hebrew
    numbering as his own (Hebrew 30:1 = English 29:40, 30:2-17 = 30:1-16); his
    Num 26:1 opens with `(19)`, Hebrew 25:19, which English counts as the
    start of 26:1, so `merge` joins the two rows. His Deut 12:32 is
    `(13:1)` and 13:1-18 `(13:2-19)`; 22:30 is `(23:1)` and 23:1-24 `(23:2-26)`
    (he has no counterpart of English 23:2 and 23:12, and prints 23:25 before
    23:24); his 29:1 is `(28:69)` and 29:2-29 `(29:1-28)`. In Deut 5 his
    `(17)`, with a brace over the four short commandments, and `(18)`-`(30)`
    beside his 21-33 are the Hebrew count; English splits Hebrew 5:17 into four
    verses and so equals Swete's own 17-33, and those markers stay out of the
    page files (a comment records them) except that his 17 (adultery) and 18
    (murder) carry our own `{=5:18}` and `{=5:17}`, as he numbers Exod 20:13-15.
    The page files keep
    the printed (Hebrew) numbers; `merge` converts them to the English
    division with `versification.tsv`, so the tables have Genesis 31 with 55
    verses and 32 with 32, Exodus 8 with 32 and 22 with 31, Leviticus 5 with 19
    and 6 with 30, Numbers 16 with 50, 25 with 18, 29 with 40 and 30 with 16,
    Deuteronomy 12 with 32, 22 with 30 and 29 with 29, and verse anchors match the English Bibles.
  - *1 Kingdoms*: his 20:43 is `(21:1)` and his 21:1-15 `(21:2-16)` (Hebrew;
    English 20:42 = Hebrew 20:42 + 21:1, so `merge` joins them); his own 24:1-23
    are Hebrew with no parentheses (24:1 = English 23:29). At 2:10 the margin
    prints 10, his own lettered `10 a` and `10 b` (Greek-only lines), then
    `(10 b)`: the page file has `{10}{=2:10a}` and his 10a/10b run on with
    common 2:10a, so the table has 2:10a and 2:10b. Where his verse starts a few
    words before a parenthesized number of the same verse (2:11, 11:1, 19:2,
    19:11, 20:38, 25:16) the words before it run on with the previous common
    verse (`{1}{=10:27}`). Chapter 18 opens at his verse 6 (`{C18}{6!}`) and
    13 at 2 (`{C13}{2!}`); Codex B lacks 13:1, 17:12-31, 41, 50, 55-58, 18:1-5,
    10-11, 17-19, 30. The unnumbered lines after 31:13 (καὶ ἐγένετο μετὰ τὸ
    ἀποθανεῖν Σαούλ ...) stay in 31:13 as printed.
    His 2 Kgdms 18:33 is `(XIX)(1)` and 19:1-43 is `(2)`-`(44)` (Hebrew 19:1 =
    English 18:33, 19:2-44 = 19:1-43), so 2 Kingdoms 18 has 33 verses and 19 has 43.
  - *3 Kingdoms*: a bare parenthesized number belongs to the Hebrew chapter of
    the last parenthesized Roman numeral printed (`20 (7) (V)`, then `21 (8)`
    = 5:8), until Swete's own chapter changes (`V (15) 1` = 5:15). Hebrew 5:1-14
    (in his 4:20-30 and 10:30) are English 4:21-34 and Hebrew 5:15-32 (his
    5:1-6:3) English 5:1-18; his own 22:1-54 are Hebrew (22:44 joins English
    22:43, 22:45-54 = 22:44-53). His XX is `(XXI)` and XXI is `(XX)`, printed
    once each with no parenthesized verse numbers: every verse carries our own
    `{=21:n}` / `{=20:n}`, so the table has Hebrew/English 21 before 20. His own
    lettered supplements (2:35a-o, 2:46a-l, 8:53a, 12:24a-z, 16:28a-h; no j,
    v, w) are `{35a}` etc. Halves with our letters where Swete prints a number
    twice: 7:1a/b (his 7:38, 7:50), 9:17a/b (`(17)` at 4:33, `(17 b-19)` at
    10:23, `{=9:17b-19}`), 11:1a/b (his XI 1 has no parenthesis; the in-text
    `(1)` follows), 11:3a/b, 11:25a/b. Common verses with no number printed
    (lacking in B, or only in the lettered supplements): 4:20, 5:5-6, 6:11-13, 6:32, 7:22, 7:31, 8:12-13, 9:23-25,
    11:39, 12:2, 12:17, 13:27, 14:1-20, 15:6, 15:32, 21:11-12, 22:47-50.
  - *4 Kingdoms*: his 11:21 is `21 (1) (XII)` and his 12:1-21 are `(2)`-`(22)`
    (leaf 800; Hebrew 12:1 = English 11:21, 12:2-22 = 12:1-21). His own
    lettered 1:18a-d (Greek-only) stay `{18a}`-`{18d}`. In-text numbers: `(4)`
    before his 1:4, `(6)` before his 4:6 and `(3)` before his 25:3 start the
    common verse there; at 15:19 his 19 stands three words before `(19)`, so
    those words run on with 15:18; at 25:10 only `(10)` is printed (no own 10,
    `{11!}` follows).
  - *A Swete number printed twice in a chapter*: 2 Kgdms 23 prints 29, then 31
    (no 30: apparatus "30 om B"), and after 39 prints 30 and 31 again (leaves
    697-698). Encoded `{31!}{=23:31a}` ... `{30!}` ... `{31!!}{=23:31b}`; the
    letters are ours, and the table runs 23:29, 31a, 32, ... 39, 30, 31b.
- **Esther's Greek additions** (leaves v2 775-800). Swete prints the six
  additions where they stand in the Greek, each numbered in the margin by a
  letter and its own verses (`A 1` ... `A 17`, `B 1` ..., to `F 11`), with the
  Vulgate chapter and verse in parentheses beside them (`(XI) (2) A 1`,
  `(XIII) (8) C 1`). The page files mark a section `{CA}{1}` and Swete's
  own verse numbers inside it; the tables have chapter `A`-`F` (`A 1` is
  `A\t1`, the build's reference `esth.A.1`, the page anchor `#esther-a-1`),
  standing in printed order between the numbered chapters: A before 1:1, B
  after 3:13, C and D after 4:17, E after 8:12, F after 10:3. Where an
  addition ends inside a chapter Swete reprints that chapter's numeral
  (`III 14` after B 7): `{C3}{14}` resumes chapter 3. D takes the place of
  5:1-2, so chapter 5 opens at `{C5}{3!}`. The numbered chapters use
  Swete's own (= English) numbers; verses the Greek lacks stay absent. The
  Vulgate numbers are not references: a `#` comment line above the printed
  line records each margin entry with a Roman numeral and any parenthesized
  number that does not run on by one with Swete's own (the others go
  verse for verse with his). `books.tsv` counts Esther's chapters as 16
  (10 numbered + 6 lettered), so the book is complete when all are present.
- **Psalms** (leaves v2 233-435). Each psalm is a chapter with Swete's own,
  Septuagint, number (`{C9}` ... `{C151}`); the Greek-numeral heading above
  a psalm (`Γʹ`, `ΡΙΓʹ`) and the Roman numeral in the margin are not text.
  Every text line is a verse line with its printed depth: `{S}` starts at
  the poetry's left edge (most numbered verses), `{S1}` is indented one step
  (most second stichs; some numbered verses), `{S2}` is the turned-over end
  of the line above (that line runs to the right edge of the block and ends
  with no punctuation; the tail is set deeper than `{S1}`). The
  superscription (small type, unnumbered) is text: every line of it starts
  `{T}`, and the first `{T}` after `{Cn}` is verse 1 of the psalm. Swete's
  first number after a title is 2 (Ps 3: the title is verse 1) or a margin
  1 (Ps 14, 113, 151: the title runs on into his verse 1, one row). Order
  on a line: `{Cn}`, then `{S}`/`{S1}`/`{S2}`/`{T}`, then `{n}`. διάψαλμα
  is text, a word at the end of its line (`... αὐτοῦ. διάψαλμα.`); ᾠδὴ
  διαψάλματος (Ps 9:17) likewise. Psalm 118 has no letter headings in the
  text (the Hebrew letters are in the apparatus only); its sections are
  separated by space, which is not marked. **Hebrew numbers**: from Psalm
  10 Swete prints the Hebrew psalm number in parentheses beside the Roman
  (`XIV (XV)`), and where the verse division differs the Hebrew verse
  numbers in parentheses in the margin (`(X) (1) 22` in Ps 9, `9 (1) (CXV)`
  in Ps 113) or in the text (`δικαία (11)ἡ βοήθεια`, Ps 7:11; `(9)Ἀλληλουιά`,
  Ps 113:1). In Psalms these are **not** `{=c:v}` markers: the tables keep
  Swete's own (Septuagint) psalm and verse numbers, and each parenthesized
  number is recorded as printed in a `#` comment line directly above its
  printed line (`# margin: XIV (XV)`, `# margin: (X) (1) 22`,
  `# in-text: (11) before ἡ βοήθειά`) for a later conversion to English
  anchors (`ursinia-vff.10`).
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
| `{C3}` | Swete's chapter 3 starts; after a lettered section, `{C3}` again where Swete reprints the numeral of the chapter it interrupted (Esth `III 14`) resumes chapter 3 at its next verse |
| `{CA}` | Swete's lettered section A starts (Esther's Greek additions A-F, the letter printed in the margin beside verse 1); its verses are `{1}`, `{2}`, ... as printed, table chapter `A`. Sections run A, B, C ... and do not advance or reset the numbered chapters |
| `{7}` | Swete's verse 7 starts (where his superscript stands); the common reference becomes chapter:7 |
| `{=2:25}` | the common reference from here until Swete's next `{n}` (his parenthesized number, in the margin or the text); may go backwards, but each common verse is given once per book |
| `{=31:48a}` | the same for a half verse (Swete's `(48 a)`, or our letters where he prints a number twice) |
| `{=40:30-31}` `{=36:34,36}` | one Swete verse for several common verses, as printed (`(30, 31)` with consecutive numbers is a range); the first may be a half verse, `(17 b-19)` = `{=9:17b-19}` (3 Kgdms 10:23) |
| `{52!}` | Swete's verse 52 as printed, out of sequence: his own numbering skips (Gen 31:52) or prints a number early or late (Num 6: 23, `{27!}`, `{24!}`, 25, 26; Num 10: 33, `{35!}`, 36, `{34!}`) or opens a chapter on a later number (1 Kgdms 18: `{C18}{6!}`); each Swete number still occurs once per chapter, except as `{n!!}`. An unmarked break in sequence fails |
| `{31!!}` | Swete's own number printed a second time in the chapter (2 Kgdms 23: 29, 31, ... 39, `{30!}`, `{31!!}`); it must have occurred before; both places of the common verse take our letters (`{=23:31a}`, `{=23:31b}`) |
| `{42a}` | Swete's own lettered verse as printed (superscript `42a`, margin `42 a` without parentheses: Josh 21:42a-d, 24:33a-b): an extra Greek verse after his 42, not a half of it; only after `{42}` or another letter of 42; table verse `42a` |
| `{P}` | the line starts an indented paragraph |
| `{S}` | the line is a line of poetry; in Psalms `{S}` at the left edge, `{S1}` indented, `{S2}` a turned-over line end |
| `{T}` | a line of a psalm's unnumbered superscription; the first `{T}` after `{Cn}` starts verse 1 |
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
   own verse order (breaks only where marked `{n!}`, each number once per
   chapter), each common verse given
   once per book, every decision settled.

Version `swete-pilot-1` (Genesis leaves 33–37, Daniel 522–527) did steps 1–4 by
hand with throwaway scripts; its measured accuracy, cost and hazards are in the
beads issue `ursinia-vff.6`.

## License

To the extent possible under law, the authors of this transcription have
waived all copyright and related or neighboring rights to it under CC0 1.0
Universal (<https://creativecommons.org/publicdomain/zero/1.0/>). No
attribution is required. Swete's printed text is itself in the public domain.
