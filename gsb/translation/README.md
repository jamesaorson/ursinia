# Greek Source Bible: translation files

The English of the Greek Source Bible (GSB), one file per chapter, written as
Scheme data (plain s-expressions; Guile's `read` loads them). Agents draft, the
owner reviews. `make gsb/lint` checks every file; `make gsb/site` renders them
at `/bible/versions/gsb/text/`.

```
gsb/translation/NN-<id>/book.scm     book decision notes (optional)
gsb/translation/NN-<id>/CCC.scm      chapter CCC, three digits: 001.scm
gsb/lexicon/glosses.scm              the concordance: lemma -> senses -> gloss
```

`NN-<id>` is the book's prefix and id from `gsb/books.tsv`, the same stem as
its Greek table `gsb/greek/NN-<id>.tsv`. Word numbers below are the `n`
column of that table: `john.1.1#5` is word 5 of John 1:1.

## Chapter file

A sequence of forms:

```scheme
(note "markdown")          ; chapter decision note; any number
(verse N item ...)         ; N an integer, or a string for lettered verses: (verse "35a" ...)
```

Verse items:

| item                                | meaning                                                                                       |
| ----------------------------------- | --------------------------------------------------------------------------------------------- |
| `(status draft)`                    | required; `draft` (agent) or `reviewed` (owner)                                               |
| `(literal seg-or-clause ...)`       | required; the hyper-literal layer                                                             |
| `(readable "text")`                 | required; the readable layer as plain text ...                                                |
| `(readable seg ...)`                | ... or aligned like the literal layer (word numbers only checked to exist)                   |
| `(untranslated (N "reason") ...)`   | Greek words deliberately left out of the literal layer                                        |
| `(note "markdown")`                 | verse note                                                                                    |
| `(note N "markdown")`               | note on Greek word N                                                                          |

A **segment** is `("english" ref ...)`. Segments are joined with single
spaces, so punctuation goes inside the text (`"the Word,"`). A **ref** names a
Greek word and the concordance sense it is translated with:

- `N` — word N in its lemma's **default sense**, the first one listed in the
  concordance.
- `(N sense)` — word N in the named sense: `(4 the)`.
- `(N sense "lemma")` — the same, overriding the table's lemma (for LXX words
  the table has not lemmatized yet).
- `(cont N)` — this segment **continues** word N, whose own ref is in an
  earlier segment (see below).

A segment covers one Greek word or several (`("did not overtake" 12 13)`).
Each Greek word belongs to exactly one segment, its own; other segments may
only continue it. A **clause** groups segments for the clause color mode:
`(clause seg ...)`; segments outside a clause are allowed.

### Supplied words

Words with nothing behind them in the Greek are in `[brackets]`, as many as
needed, anywhere in a segment:

- A segment whose words are all supplied has no refs: `("[the]")`. Punctuation
  may stand outside the brackets: `("[one].")` (Genesis 2:23).
- A segment with Greek behind it may also hold supplied words: `("of [the]
  field" 4)` (Genesis 2:5), `("leaves" 14) ("of [a] fig tree" 15)` (3:7).
  Supplied words are skipped when the segment's gloss and articles are
  checked, so `[the]` needs no Greek article and the `of` still belongs to the
  genitive noun.

### One Greek word, English in pieces

When English needs other words inside one Greek word's rendering, give the
word to the segment where its English starts and mark each later piece
`(cont N)`. The gloss check reads the pieces together; on the page, pointing at
either piece highlights both and the Greek word.

```scheme
;; Genesis 3:23 ἐξαπέστειλεν² αὐτὸν³: "sent him out"
("sent" 2) ("him" 3) ("out" (cont 2))
;; Genesis 1:6 Γενηθήτω⁵ στερέωμα⁶: "Let [a] firmament come to be"
("Let" 5) ("[a]") ("firmament" 6) ("come to be" (cont 5))
;; Genesis 1:22 καὶ¹⁷ τὰ¹⁸ πετεινὰ¹⁹ πληθυνέσθωσαν²⁰: "and let the birds multiply"
("and" (17 and)) ("let" (20 multiply "πληθύνω")) ("the birds" (18 the) 19) ("multiply" (cont 20))
```

A `(cont N)` takes no sense or lemma (it shares its word's). It must come after
the word's own segment, and a segment cannot both own and continue a word.
The aligned readable layer may use `(cont N)` the same way.

### Adding a sense to a lemma

A bare `N` means the lemma's first sense, so adding a second sense does not
break earlier chapters. Add the new sense **after** the established one, then
review the lemma's earlier uses and name the new sense where it fits:

```sh
make gsb/uses LEMMA=ἀρχή      # or ./scripts/gsb-check.sh --uses ἀρχή
```

```
ἀρχή: senses beginning, rule (default: beginning)
gen.1.1#2	ΑΡΧΗ	beginning	"beginning"
gen.1.16#15	ἀρχὰς	rule	"rules"
```

Each line is the word's address, its Greek, the sense (`(default)` when the
ref is bare) and its English, with `(cont N)` pieces joined by `…`.

## Book file

Only `(note "markdown")` forms.

## Concordance: `gsb/lexicon/glosses.scm`

```scheme
(lemma "ὁ"
  (sense the
    (gloss "the")
    (why "The article, rendered \"the\" wherever English can carry it."))
  (sense unrendered
    (gloss "")
    (why "English puts no article before \"God\" or a personal name ...")))
```

One `(lemma ...)` per lemma, spelled exactly as in the table's `lemma` column.
Each sense has a name (a symbol, unique in the lemma), a `gloss` list and a
`why`. The first sense listed is the default. The first gloss is the gloss;
the rest are its accepted English forms (plural, past, the progressive ...),
all of the *same* English word. A new English word for the same lemma means a
new sense with its own `why`. `(gloss "")` means English leaves the word
unrendered (it is still aligned, so its color shows). A sense may add
`(readable "word")` when the readable layer uses a different word from the
literal gloss (ἐπιφέρω: literal "borne", readable "moving"); it is shown in
the concordance on the page and not checked.

## Readable layer: `gsb/lexicon/readable-avoid.scm`

The readable layer uses words people understand today. Words it must not use
are listed with their replacement and reason:

```scheme
(avoid "borne"
  (use "moving")
  (why "\"was being borne over the water\" is not natural modern English ..."))
```

`make gsb/lint` fails when a readable layer (plain string or segments)
contains a listed word or phrase as whole words, case-insensitive, naming the
replacement. The literal layer is not checked against this list. Add an entry
whenever the owner rejects a word for the readable layer.

## What `make gsb/lint` checks

- every Greek word of a verse is in exactly one literal segment as its own, or
  in `untranslated` with a non-empty reason; a `(cont N)` comes after word N's
  own segment;
- a segment whose words are all `[supplied]` has no Greek; any other segment
  has at least one Greek word; brackets are balanced and not nested;
- an unbracketed `the` needs a Greek article (lemma `ὁ`) among the segment's
  words; an unbracketed `a`/`an` needs `τις` or `εἷς` — otherwise bracket it;
- each word's lemma is in the concordance, the sense exists (a bare number
  takes the first), and the word's English (its segment and `(cont N)` pieces,
  without supplied words) contains one of that sense's glosses (whole words,
  case-insensitive) unless the gloss is `""`;
- **the source's ambiguity is kept** (gsb/AGENTS.md rule 9), in the literal
  layer and an aligned readable layer:
  - a segment aligned to a demonstrative (οὗτος, ἐκεῖνος, ὅδε) whose English
    has a personal pronoun (he, she, it, they ...) or a name but no
    this/that/these/those is an error;
  - a name (a capitalized gloss of a sense named `name`, or "God"/"Lord") in
    a segment none of whose Greek words has that lemma is an error, supplied
    or not;
  - a plain-string readable layer may not use a name more often than the
    literal layer; when the literal layer renders a demonstrative with
    this/that/these/those and the readable layer has none of those words, a
    **warning** is printed (it does not fail);
- the readable layer avoids the words in `gsb/lexicon/readable-avoid.scm`;
- the verse exists in `gsb/greek/`, appears once, and every word number in
  segments, `untranslated` and word notes exists;
- `status` is `draft` or `reviewed`; no unknown items;
- the concordance is well formed: one entry per lemma, unique sense names,
  every sense with a gloss and a `why`; the avoid list likewise.

Every error names the file, the verse and what to do.

## Worked example: John 1:1

Greek (`gsb/greek/63-john.tsv`): Ἐν¹ ἀρχῇ² ἦν³ ὁ⁴ Λόγος⁵, καὶ⁶ ὁ⁷ Λόγος⁸ ἦν⁹
πρὸς¹⁰ τὸν¹¹ Θεόν¹², καὶ¹³ Θεὸς¹⁴ ἦν¹⁵ ὁ¹⁶ Λόγος¹⁷.

```scheme
(note "**Opening (1:1-5).** The prologue answers Genesis 1:1 LXX ...")

(verse 1
  (status draft)
  (literal
    (clause ("In" 1) ("[the]") ("beginning" 2) ("was" 3) ("the Word," (4 the) 5))
    (clause ("and" 6) ("the Word" (7 the) 8) ("was" 9) ("with" 10) ("God," (11 unrendered) 12))
    (clause ("and" 13) ("the Word" (16 the) 17) ("was" 15) ("God." 14)))
  (readable ("In the beginning" 1 2) ("was" 3) ("the Word," 4 5) ("and the Word" 6 7 8) ("was" 9)
            ("with God," 10 11 12) ("and the Word" 13 16 17) ("was" 15) ("God." 14))
  (note "Last clause: the Greek order is θεὸς ἦν ὁ λόγος ...")
  (note 14 "θεός without the article, placed first for emphasis ..."))
```

Renders as: *In [the] beginning was the Word, and the Word was with God, and
the Word was God.* Reading it against the rules: `"[the]"` is supplied (Greek
has no article before ἀρχῇ), so it is bracketed and has no refs; `(4 the)`
names the `the` sense (also `ὁ`'s default, so a bare `4` would mean the same); `"God,"` covers τὸν Θεόν
with the article in its `unrendered` sense; `"the Word"` in the last clause
comes before `"was"` because English marks the subject by position — the
order change is explained in the verse note. Every word 1–17 appears once.

## Adding a translated chapter

1. Check the Greek exists: `gsb/greek/NN-<id>.tsv` (else run `make gsb`, or
   the book is not transcribed yet).
2. List the verse's words: `awk -F'\t' '$1=="john.1.6"' gsb/greek/63-john.tsv`.
3. Write `gsb/translation/NN-<id>/CCC.scm`, verse by verse, `(status draft)`.
4. For each new lemma or new sense, add it to `gsb/lexicon/glosses.scm`
   with its `why` before using it; a new sense goes after the established
   one, then review the earlier uses with `make gsb/uses LEMMA=...`.
5. Record chapter decisions as `(note ...)` at the top; book-wide ones in
   `book.scm`.
6. `make gsb/lint` until clean, then `make gsb/site` and look at the page.
7. The owner changes `draft` to `reviewed`.
