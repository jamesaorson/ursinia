---
name: gsb-transcribe
description: Transcribe pages of H. B. Swete's Septuagint ("The Old Testament in Greek") from archive.org page scans into gsb/sources/swete/pages/, for the Greek Source Bible. Use when asked to transcribe Swete leaves or pages (e.g. "transcribe Genesis leaves 39-43"), to settle or check a Swete page's decisions, or to see which Swete pages are done or missing.
---

# Transcribing Swete page by page

You turn page images into our own public-domain (CC0) transcription. Each leaf
(scan page) you are given ends as one page file, `gsb/sources/swete/pages/<book>/vN-LLLL.txt`,
and one decision log beside it, `vN-LLLL.decisions.tsv`, both checked by the tools
and stamped done. Other agents are doing other leaves at the same time.

Three readings of every page, all from the image: (A) archive.org's OCR,
(B) a fresh Tesseract `grc` pass, (C) **your own reading of the image in
strips**. C is the transcription; A and B only tell you where to look again.
Every disagreement, and every place where both OCRs are known to fail together,
is settled against an enlarged crop of the image and logged.

## Hard rules

- **Only the page images.** Never look at, search for, or paste from any other
  digital text of the Septuagint (Rahlfs, CCAT, eliranwong/LXX-Swete, First1KGreek,
  Perseus, Wikisource, Bible software, your own memory of "the" text). If you
  catch yourself "knowing" a word, read it from the image anyway. Swete prints
  what Codex A/B has, misprints included; we keep exactly that.
- **Only your leaves.** Write only the page and decision files of the leaves you
  were given. Never edit another leaf's files, `decisions.tsv`, `provenance.tsv`
  or the `NN-<id>.tsv` tables, and never run `merge` (the coordinator does).
  If a neighbor's page looks wrong, say so in your report.
- **No guessing in silence.** Damaged, faint or ambiguous print gets your best
  reading *and* a logged decision that says it is ambiguous (see step 7).
- No git commits or pushes. No Python. Images stay in the cache, never in the repo.
- **Edit Greek text with the edit tools** (Edit/Write), never `perl -pi`,
  `sed -i` or shell redirection: they mangle combining characters and NFC.
- **Pass BOOK and LEAF as separate arguments.** In zsh a variable holding
  `lev 275` is not split into two words (`L="lev 275"; ./scripts/gsb-swete.sh
  collate $L` fails); write `collate lev 275`, or use two variables.

## Setup (once per session)

```sh
./scripts/gsb-swete-fetch.sh doctor      # every line must be ok; it prints the fix otherwise
./scripts/gsb-swete.sh status gen        # what is done / wip / missing / failing
```

Leaves per book are in `gsb/sources/swete/leaves.tsv` (Genesis: vol. 1, leaves
33–135 = printed pages 1–103; leaf = page + 32). Work in batches of about
**5 leaves per fresh context**: a leaf costs roughly 10–20 image reads.

## Per leaf (repeat for each leaf, in order)

Examples use Genesis leaf 39; replace `gen` / `1` / `39` with yours.

### 1. Fetch

```sh
./scripts/gsb-swete-fetch.sh 1 39
```

The first run in a cache downloads the volume's OCR (~85 MB) and the grc model.

### 2. Main-text box

```sh
./scripts/gsb-swete.sh box gen 39
```

This creates the page file (two header lines: scan/leaf and box; `done` adds
the third) with a suggested box and writes
`box.png` (path printed). **Read box.png.** The red box must hold every
main-text line and nothing else: running head (top), margin verse numbers and
manuscript sigla (A, D, E, ¶D, §D, ... left and right; they swap sides between
even and odd pages), the apparatus (small unaccented text at the bottom). Set it
by hand if needed, in page pixels (the preview is scaled to 1000 px wide, so
multiply what you see by page-width/1000):

```sh
./scripts/gsb-swete.sh box gen 39 Y0 Y1 X0 X1
```

The preview is small; do not trust pixel estimates from it. The strips (next
step) are the real check: if a strip shows a word cut off at its left or right
edge, or a first or last printed line missing, fix the box and **rerun
`strips`** (and `collate`, if you had run it: it carries your settled decisions
over to the new OCR readings and drops TODO rows that no longer apply).
A leaf shared with another book or text (a book's first or last page; Daniel's
facing Old Greek / Theodotion pages are separate leaves) gets a box around
*this* text only. **Err loose on the left**: a sliver of a margin number or
siglum inside the box costs a settled-by-class row at most, while a clipped
first letter costs the OCR the whole word. On the right, keep margin numbers
out if you can (they sit ~20 px from the text). The suggestion was tuned on the
Genesis boxes; its known misses are a last line after a paragraph gap and the
right edge of a page of poetry (Gen 49), so check the bottom and, for poetry,
the longest line.

### 3. Strips

```sh
./scripts/gsb-swete.sh strips gen 39
```

Read every `strip-NN.png` (5 printed lines each, at full resolution, slightly
overlapping). Strip line numbers come from the OCR; trust the image.

### 4. Write the page file

Append the text to `pages/gen/v1-0039.txt` below its `#` header lines (keep
them). **One printed line per line, exactly as printed.** See *Page format*
below for markers and conventions. Look again at any word you are not sure of
with `zoom` (step 6) before moving on.

### 5. Collate

```sh
./scripts/gsb-swete.sh collate gen 39
```

It aligns A and B with your text token by token and writes the leaf's
`.decisions.tsv`: known OCR failure classes are settled automatically (class
R0–R7, see below), everything else is a `TODO` row, printed with its row
number, readings and a crop: `-> sheet-02.png #3` means the 3rd crop on that
sheet (in the leaf's work directory), the word underlined in red, enlarged 3×.
NOTEs: a line-count mismatch (you dropped or doubled a line, or the OCR split
one) and lines that look indented (a paragraph you have not marked with `{P}`).

### 6. Settle every TODO row against the image

Read the sheets. For each row decide what the print shows:

```sh
./scripts/gsb-swete.sh decide gen 39 4@97tpd 'image (3x): rough breathing'           # you were right
./scripts/gsb-swete.sh decide gen 39 7,9@97tpd 'image (3x): acute before capitalized quotation'
./scripts/gsb-swete.sh decide gen 39 12@97tpd 'image (3x): Γ, not Τ' 'Γενηθήτω'         # chosen = what the print has
```

Without CHOSEN, `decide` records what the page file says at that row now
(reading C), so edit the page first and then decide; with CHOSEN it records
that reading. If the page changed in a way that renumbers rows, it asks you to
collate again.

`@97tpd` is the **rows revision** the last `collate` printed ("Rows revision
97tpd"). Every collate after a page edit can renumber the rows; `decide`
refuses a revision that is no longer current ("rows were renumbered by the
last collate: list them again ..."), so old row numbers can never settle the
wrong rows. Settling rows and `flag` do not change the revision.

When the chosen reading differs from your page file, **edit the page file** to
match (collate and done refuse a mismatch). If a crop is unclear, zoom further:

```sh
./scripts/gsb-swete.sh zoom gen 39 14            # line 14 in three pieces, 2x (add a scale: 14 3)
./scripts/gsb-swete.sh zoom gen 39 600 900 1100 1000 4   # any rectangle X0 Y0 X1 Y1, 4x
```

`zoom LINE` counts lines the way `collate`, `decide` and `flag` do: the page
file's text lines, `#` lines not counted. It finds the OCR line those words
align to and prints both (`page line 14 = OCR line 13: <your text>`); check
the text it prints. Before the page file has text, LINE is the OCR's line, as
in the strips. For a single word, the rectangle form at 6-8x with the word's
box is sharper; compare it with a clear example of the same glyph on the page.

The basis says what you saw: `image (3x): smooth breathing`, `image: speck, not a
period`, `image: Τ, not Γ`. Rerun `collate` after edits; it keeps your decisions
(matched by line and OCR readings) and adds rows for new disagreements. Repeat
until it reports 0 open and no "chose ... but the page now says" note.
Collate reconciles the file with the page and OCR every time: a settled
decision follows its word when a line is added or removed above it, or when a
new box changes the OCR readings; a TODO row that no longer matches any
disagreement is dropped; a settled row that matches nothing is kept (a NOTE
says so only if its word has left the page). Never edit the decisions file by
hand: the open count collate prints is exactly what `done` checks, and `done`
refuses a decisions file that collate would rewrite. `decide` with CHOSEN says
whether the page already reads that way; if not, edit the page.

### 7. Damaged or ambiguous print

Write your best reading and log it, even if no OCR disagreed:

```sh
./scripts/gsb-swete.sh flag gen 39 22 'Ἀσσυρίων,' 'ambiguous: mark after the word is half comma half period; read comma'
```

WORD must be on that line as in the page file (punctuation included; `¶` `§`
and `{...}` markers may be given or left out); `flag` refuses otherwise and
prints the line's words.

Never invent text for a hole in the scan; if words are unreadable, stop and
report the leaf to the coordinator instead of finishing it.

### 8. Mandatory checks (already in the TODO rows; do not skip them)

Both OCRs fail *together* here, so agreement means nothing:

- **H1 breathing on a capital** (Ἀ/Ἁ, Ἐ/Ἑ, Ὁ/Ὀ, Εὐ/Εὑ). Rough looks like a
  reversed comma (‘, opening left), smooth like an apostrophe (’). Examples
  from the pilot: Ἁνανίας, Ἁμελσάδ, Εὑειλάτ.
  **Breathing + accent on a capital** sits to the left of the letter and comes
  in four shapes (checked on Gen-Num, `ursinia-vff.14`), the same as over a
  lowercase vowel:
  rough + grave is one compact closed mark like a small `d` (Ὃς Exod leaf 177
  l18, Ἓξ leaf 181 l11, every Ὣρ);
  rough + acute is an open curl like `c` then a separate rising stroke (Ὅσα
  Num leaf 361 l12, Ὅρα leaf 286 l10, Ὥσπερ Lev leaf 250 l3);
  smooth + acute is an apostrophe then a rising stroke, like `”` (Ὤφθη Gen
  leaf 99 l4, Ὄφελον Num leaf 316 l15, Ὄρθρισον Exod leaf 150 l30);
  smooth + grave is an apostrophe then a stroke falling to the right, like
  the mark on ἂν (Ὢγ Num leaves 335, 343, 361; Ἢρ; Ὢς). The test between
  the two graves is whether the mark is closed (rough) or open with two
  parts (smooth); zoom at 8x or more and set it beside ἂν and ὃς on the page.
- **H2 accent before an enclitic** (σου, μου, με, τε, ἐστιν, τις, ...): Swete
  writes ὅ τε, καλόν σου, φωνήν σου.
- **H3 accent before a capitalized word**: Swete puts an acute (not grave) on an
  oxytone before a capitalized quotation: `εἶπεν ὁ θεός Γενηθήτω`.

### 9. Done

```sh
./scripts/gsb-swete.sh done gen 39
```

It re-collates and checks the leaf (markers, NFC, characters, brackets, verse
order, every row settled) and stamps `# done DATE swete-2`. Fix what it lists
and rerun. Then `status gen FIRST LAST` for your range.

**Per-leaf checklist** (done checks the starred ones):
- [ ] box excludes head, margins, apparatus (you looked at box.png)
- [ ] every printed line of the main text is in the file, in order, one per line*
- [ ] {Cn} and {n} where Swete prints them; {=c:v} wherever a parenthesized
      number stands, in the margin or in the text; {P} at indented paragraph starts
- [ ] verse numbers continue from the previous leaf (status checks across leaves)
- [ ] every TODO settled, page file agrees with every decision*
- [ ] ambiguous print flagged
- [ ] `done` passes*

## Page format

```
# theoldtestamenti00unknuoft leaf 0039 (printed page 7)
# box 230 2720 268 1999
# done 2026-11-26 swete-2
πρὸς τὸν κύριον Μείζων ἡ αἰτία μου τοῦ ἀφεθῆναί με. {14}εἰ ἐκβαλεῖς με
{P}§{1}Ἀδὰμ δὲ ἔγνω Εὕαν τὴν γυναῖκα αὐτοῦ, καὶ συνέλαβεν καὶ ἔτεκεν
```

The `#` header lines are written by the tools: two until `done` adds the
third. Text lines:

| Mark | Meaning |
|---|---|
| `{C4}` | Swete's chapter 4 starts here (the Roman numeral in the margin). Put it right before the chapter's `{1}`. |
| `{7}` | Swete's verse 7 starts here: where the superscript number stands in the text. |
| `{=2:25}` | The **common** reference from here on, from a number Swete prints *in parentheses*, in the margin or inside the text, e.g. `(25)(II)` = 2:25, `(1)(III)` = 3:1. Put it where that verse starts in the text (after Swete's own `{n}` if both start there). It holds until Swete's next `{n}`, which resets the common reference to Swete's number; so every verse that differs needs its own `{=c:v}`. It may go backwards (the Septuagint transposes verses), but each common verse may be given only once per book. |
| `{=31:48a}` | A half verse: Swete's margin prints `(48 a)`, `(48 b)`, or an unparenthesized `52 b` beside his own number. Keep the letter; the table gets verse `48a`. A whole verse and its halves cannot both appear. **Also** where Swete prints the same parenthesized number twice in a book (Exod 25:34 on leaf 186, 39:40 on leaf 217): the first place gets `a`, the second `b`, and a `#` comment says the letters are ours, not printed. |
| `{=40:30-31}` `{=36:34,36}` | One Swete verse for several common verses: the margin prints `(30, 31)`, `(19-22)`, `(34, 36)`. Consecutive numbers are a range (`(4, 5)` = `{=37:4-5}`), others a list in ascending order; the table gets one row, verse `30-31`, and every verse in it counts as given. A list member printed twice elsewhere takes its letter: `{=36:34,36b}`. |
| `{52!}` | Swete's verse 52 starts here **and his own number is printed out of sequence**: it really skips (he prints no 51), or comes early or late (Num 6 prints 23, 27, 24, 25, 26: `{27!}` and `{24!}`; Num 10 prints 33, 35, 36, 34: `{35!}` and `{34!}`). Mark every number that does not follow the one before by one. Without `!` a break fails as a misread number; with `!` and none it fails too; a Swete number twice in a chapter always fails. |
| `{P}` | New paragraph: the line is indented in print. First thing on the line. (A blank-line gap before a paragraph, as before Gen 6:9, is not marked separately.) |
| `{S}` | A line of poetry: Swete sets a song or oracle as indented verse lines (Gen 4:23–24). Put `{S}` first on every such line, whatever its indent depth; the introducing prose line (`εἶπεν δὲ Λάμεχ ...`) gets none. |
| `¶` `§` | Witness marks printed *in the text* (a fragmentary manuscript stops / resumes). Keep them where they stand. The `¶D` / `§D` in the margin are not text. |
| `[` `]` | Swete's brackets (letters lost in Codex A in Genesis). Keep as printed, even inside a word or across lines/pages. |
| line ends in `-` | Hyphenated word continued on the next line (or the next page's first line). Keep the hyphen. |
| `# ...` | Comment. |

Example of Swete's own numbering against the common one (Gen 2:24–3:1, leaf 36):

```
καὶ ἔσονται οἱ δύο εἰς σάρκα μίαν. {C3}{1}{=2:25}καὶ ἦσαν οἱ δύο γυμνοί, ὅ τε
Ἀδὰμ καὶ ἡ γυνὴ αὐτοῦ, καὶ οὐκ ᾐσχύνοντο.
{P}{=3:1}Ὁ δὲ ὄφις ἦν φρονιμώτατος πάντων τῶν θηρίων τῶν ἐπὶ τῆς γῆς
```

Swete's 3:1 (page file) is common 2:25 + 3:1 (verse table). The same happens
at Gen 6:1 (margin `(32) VI 1` and then `(VI) (1)`): `{C6}{1}{=5:32}Καὶ ἦν Νῶε ...`
and, on the next indented line, `{P}{=6:1}Καὶ ἐγένετο ...`. If you meet a
pattern that does not fit `{=c:v}` (a parenthesized number with no Swete
verse of its own nearby, chapters running in parallel), stop and report it.

**Transposed verses** (Gen 35:16–22, leaf 99). Swete prints `(21) 16` before
Ἀπάρας, `(16)` before ἐγένετο, and `(22) 21` later: the Septuagint puts 35:21
before 35:16. Encode what is printed; the table keeps this order (35:21, 35:16,
35:17 ...), and the order check applies only to Swete's own numbers:

```
{P}{16}{=35:21}Ἀπάρας δὲ Ἰακὼβ ἐκ Βαιθὴλ ἔπηξεν τὴν σκηνὴν αὐτοῦ ἐπέκεινα
τοῦ πύργου Γάδερ. {=35:16}ἐγένετο δὲ ἡνίκα ἤγγισεν χαβραθὰ εἰς γῆν ἐλθεῖν
...
ἡμέρας. {21}{=35:22}ἐγένετο δὲ ἡνίκα κατῴκησεν Ἰσραὴλ ἐν τῇ γῇ ἐκεί-
```

Swete's 22 that follows is also common 22: the same reference running on is
one row, not a duplicate.

**Half verses and a skip** (Gen 31:46–53, leaf 92). Margin: `(48 a)`, `47`,
`48 (51)`, `(52 a)` (with `(52)` also printed in the text), `(48 b)`, `49`,
`50 (50 a)`, `52 b`; Swete has no verse 51:

```
καὶ ἔφαγον καὶ ἔπιον ἐκεῖ ἐπὶ τοῦ βουνοῦ. {=31:48a}καὶ εἶπεν αὐτῷ Λαβάν
Ὁ βουνὸς οὗτος μαρτυρεῖ ἀνὰ μέσον ἐμοῦ καὶ σοῦ σήμερον· {47}καὶ
...
Βουνὸς μαρτυρεῖ. {48}{=31:51}εἶπεν δὲ Λαβὰν τῷ Ἰακώβ Ἰδοὺ ὁ βουνὸς οὗτος
καὶ ἡ στήλη αὕτη ἣν ἔστησα ἀνὰ μέσον ἐμοῦ καὶ σοῦ· {=31:52a}μαρτυρεῖ ὁ
βουνὸς οὗτος, καὶ μαρτυρεῖ ἡ στήλη αὕτη· {=31:48b}διὰ τοῦτο ἐκλήθη τὸ
...
ἑτέρου. {50}{=31:50a}εἰ ταπεινώσεις τὰς θυγατέρας μου, εἰ λήμψῃ γυναῖκας
ἐπὶ ταῖς θυγατράσιν μου, ὅρα, οὐθεὶς μεθ᾽ ἡμῶν ἐστίν. {52!}{=31:52b}ἐάν τε
```

**Parenthesized numbers inside the text.** Swete sometimes prints the common
number in parentheses a few words away from his own superscript, inside the
line: Gen 15:21, 19:4, 22:4, 22:16, 23:5–6, 23:14–15, 24:19, 24:25–26, 31:54,
47:6. It is a `{=c:v}` like a margin one, placed where the parenthesized
number stands (never typed as text):

```
{=22:4}τῇ ἡμέρᾳ τῇ τρίτῃ. {4}καὶ ἀναβλέψας Ἀβραὰμ τοῖς ὀφθαλμοῖς ἴδεν
```

(leaf 66, printed line 32: the common verse starts at the `(4)` in the text, three
words before Swete's own superscript 4; the two run on as one row). A parenthesized number that cannot be right is recorded as
the evidence shows, with a `#` comment line above it in the page file and a
`flag` row: at Gen 49:24 (leaf 132 line 24) Swete prints `(24)` before παρὰ
θεοῦ τοῦ πατρός σου, four lines after his own 24 began; common 49:25 begins
with these words, so it is a misprint for `(25)` and is encoded `{=49:25}`.

Swete's chapter 32 runs one ahead of his margin throughout (his 31:55 is
common 32:1, his 32:1 is common 32:2, ...): every verse gets its `{=32:n}`,
and a forgotten one fails as a duplicate common reference. Write the numbers
as printed, even where they follow the Hebrew chapter division (Gen 32:1,
Exod 7:26-8:28, 21:37-22:30, Lev 5:20-6:23, Num 17:1-28, 25:19, 30:1-17,
Deut 13:1-19, 23:1-26, 28:69-29:28): `merge` converts them to the English division
with `gsb/sources/swete/versification.tsv`.

**A Swete verse with no parenthesized number inside a stretch where the
numbering differs** (Exod 35-40: e.g. leaf 208, Swete 35:13 and 35:14 between
`12 (17)` and `15 (13)`). Without a marker it falls back to Swete's own number,
which another verse already holds (status fails) or which belongs to another
chapter (status warns). It has no counterpart of its own: run it on with the
common verse before it, `{13}{=35:17}`, with a `#` comment line above saying
what the margin prints and a `flag` row. Where Swete's own number simply equals
the common one (Exod 28:24-25 between `23 (29)` and `26 (30)`: the verses match
common 28:24-25) leave it unmarked.

**Conventions** (transcribe, never normalize):

- Main text only: no running head, page number, margin numbers or sigla, apparatus.
- Accents, breathings, iota subscripts, capitals and spelling exactly as printed:
  Swete's acute before a capitalized quotation, lowercase after a period,
  unaccented capitals in a book's opening words (`ΕΝ ΑΡΧΗ`, `ΕΠΙ`, `ΤΑΥΤΑ`),
  apparent misprints.
- UTF-8, NFC. Ano teleia `·` (U+00B7), question mark `;` (U+003B), elision
  `᾽` (U+1FBD, e.g. `καθ᾽`). No Latin letters, digits or other symbols outside markers.
- **Letter numerals**: Swete prints a keraia after a numeral (`ιβ΄` = 12,
  Exod 15:27; `κ΄` = 20). Write it as `ʹ` (U+02B9, which is what NFC makes of
  U+0374 GREEK NUMERAL SIGN) right after the letters: `ιβʹ`. Not an apostrophe
  `'`, not the tonos `΄` (U+0384); the checker refuses those, and refuses `ʹ`
  anywhere but after a Greek letter. Type it with `printf 'ʹ'` or copy it
  from here.
- A page that starts mid-verse simply starts with the text; one that starts
  mid-word starts with the word's second half (the previous page ends in `-`).
- Wide spaces inside a line (Swete's section breaks) are a single space; the
  capital that follows (`Καὶ`) is what marks them.
- Misprints stay: `Ἑιὼχ` for `Ἑνὼχ` (Gen 5:19), and get a decision row
  saying `image (3x): misprint ..., kept as printed`.
- Swete's **editorial asterisk** in the text, tied to a margin or apparatus
  note (Gen 37:1, leaf 102, beside Κατῴκει), is apparatus, not text: leave it
  out, like the margin sigla.
- A question mark has a thin space before it in print (`ἐστιν ;`): write it
  against the word (`ἐστιν;`). Collate joins the OCR's lone `;` to its word,
  so this raises no row.

## Hazards from the pilot

- **Γ read as Τ** and **Εὑ/Ἐν**, **ὁ/ὃ/ὅ**, **ἡ/ᾗ/ἧ**: letters and diacritics OCR
  confuses; the crop decides.
- **Specks read as periods or commas** (vol. III especially): a real point has
  the weight of the surrounding ink; a speck is lighter, smaller or off the
  baseline. Log `image: speck, not a period`.
- **Superscript verse numbers** fuse into the next word in OCR (`3καὶ`): not text.
- **Running head merged into the first line** in archive.org's OCR: why the box
  matters; read line 1 from the image.
- **Margin sigla swap sides** between even and odd pages; a `§D` in the margin
  is not the `§` in the text (which you keep).
- **Capitals at book openings** are unaccented and may be larger type; a big
  title (`ΓΕΝΕΣΙΣ`, `ΕΞΟΔΟΣ`) stays outside the box.
- **Hyphenated line breaks**: keep both halves on their lines; check the
  hyphen is printed (not a speck).
- **Daniel**: Old Greek on even leaves (book `dan`), Theodotion on the facing
  odd leaves (`dan-th`), chapter by chapter. Never mix them.
- **Indented paragraph lines** are easy to miss: collate NOTEs flag them.
- **Swete's versification** differs from the common one in places: look at every
  margin for parenthesized numbers (Gen 2:25, 5:32 so far).
- **Breathings on small letters** (εὗρεν, ηὑρίσκετο, Εὕαν's υ) are not all in
  the mandatory checks; when unsure, `zoom` the line and log it with `flag`.
- **Broken type**: a letter can print as dots (`γεννῆσα:` for `γεννῆσαι`,
  Gen 5:7). Read the word, and settle it as `ambiguous: ...`.
- **Hollow-ring points** from worn type (often in Genesis 21–27): a period or
  ano teleia prints as a small open ring. Its height decides: on the baseline a
  period, raised an ano teleia. Log `ambiguous: period prints as a small hollow
  ring (worn type); read period`.
- **Indent NOTEs** judge a line by its first Greek word against the page's
  usual left edge; a line both OCRs started late (they lost its first word) or
  that starts with a superscript verse number is not judged, and `{S}` lines
  are not required to look indented. A NOTE is a hint; the image decides.

## Classes collate settles by itself

R0 OCR lost the word (and the other OCR agrees with you) · R1 verse superscript
fused into the word · R2 ano teleia read as `" : '` · R3 junk appended (accent
row, margin) · R4 brackets dropped · R5 Latin look-alike letters (`Kal`) ·
R6 one OCR agrees with you and the other has different letters · R7 one OCR
agrees with you and the other only lacks diacritics. Everything else is TODO:
both OCRs against you with letters or diacritics differing (DIA), no OCR
reading at all, and the H1–H3 checks.

## Pilot leaves

Genesis leaves 33–37 and Daniel leaves 522–527 come from the pilot (stamped
`swete-pilot-1`); their decision files use the pilot's OCR extraction. Do not
run `collate` or `done` on them: collate would add rows that no longer match
and status would then fail them.

## Coordinator

```sh
./scripts/gsb-swete.sh status gen               # all of Genesis; exit 1 if any leaf fails
./scripts/gsb-swete.sh status gen 39 60         # a range
./scripts/gsb-swete.sh merge                    # tables, decisions.tsv, provenance.tsv
```

`status` says per leaf `done`, `wip` (file exists, not stamped), `missing` or
`FAIL` with the reasons (Swete's own verse out of sequence across leaves, a
common verse given twice, unbalanced brackets, non-Greek or non-NFC text,
unknown markers, TODO rows on a done leaf). A leaf that is not done ends the
order and duplicate checks: the next leaf starts fresh (no chapter carried
over) and gets a warning that its checks against earlier leaves were skipped
because that leaf is unfinished; they run once it is done.
Warnings (a common reference that jumps; a Swete verse with no `{=c:v}` that
lands in another chapter than the common verse before it) do not fail a leaf.
`done` also refuses a leaf that gives a common verse another page file
already gives, and names that leaf.
`merge` builds each book's verse table from the done leaves from the book's
first leaf up to the first gap, so a verse or word that crosses into a leaf
another agent did comes out whole once both are done.
