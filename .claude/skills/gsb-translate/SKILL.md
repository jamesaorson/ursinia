---
name: gsb-translate
description: Extend the Greek Source Bible's scripted hyper-literal Old Testament (gsb/literal/) for a chapter range of one book - analyze the Septuagint word forms the generator does not know yet, add concordance entries, generate the chapters, and review them verse by verse, fixing only data (form rows, gloss fields, overrides). Use when asked to "translate", "analyze forms for", "generate" or "review" Septuagint chapters for the GSB (e.g. "follow the gsb-translate skill for Genesis chapters 5-6").
---

# Extending the scripted literal layer

The literal English of the Old Testament is **generated** by
`./scripts/gsb-literal.sh` from data. You never write English verses. You add
and correct the data the generator reads, regenerate, and read the result.
Other agents are doing other chapters at the same time.

Two jobs, normally done together for your chapter range:
1. **Analyze forms**: make every Greek word of the chapters known to the
   generator (grammar tag, lemma, concordance entry).
2. **Review the chapters**: generate, read every verse against the Greek, fix
   what the data can fix, report the rest.

**Batch size:** one agent context does about **2 chapters** (roughly 1,000-
1,500 Greek words, typically 100-150 new forms and 50-120 new lemmas, plus the
review). Stop and report rather than start a third chapter.

## Before you start (every time)

1. Read `gsb/AGENTS.md` in full. Rules 1, 8, 9, 13, 16 and **16a** govern this
   work. Then read `gsb/literal/README.md` (formats and rendering rules) in
   full. Do not edit `gsb/AGENTS.md`. (Where it still says
   `gsb/lexicon/glosses.scm`, read `gsb/lexicon/glosses/`: the concordance
   is now one file per initial letter.)
2. Find your book's prefix and id in `gsb/books.tsv` (Genesis: `01`, `gen`).
   Your files are `gsb/literal/forms/NN-<id>.tsv` and
   `gsb/literal/overrides/NN-<id>.scm` (create them with the same header and
   comment line as `01-gen.*` if missing).
3. Check the chapters exist in `gsb/greek/NN-<id>.tsv`
   (`./scripts/gsb-literal.sh todo <id> <chapters>` dies with a message if not).
4. Do not run `make serve`, start or stop any web server, or touch a process
   on port 8081. No git commits, pushes or branches. Guile and POSIX sh only.
   Use the file edit tools for every data file (never shell redirection into
   a source file).

## Hard rule: your sources (rule 1)

Analyses, lemmas and glosses come **only** from your own knowledge of Greek,
applied to our text, plus the public-domain/CC0 data already in the repo:
`gsb/greek/*.tsv` (the New Testament tables carry lemmas and tags),
`gsb/lexicon/strongs.tsv`, `gsb/sources/*`, and our own concordance.
**Never** consult, search for or copy: Rahlfs/CCAT LXX morphology or text,
LSJ or any Perseus data, Morpheus, NETS, Brenton (not even as a crib), the
Göttingen edition, Lexham, Logos/Accordance/BibleWorks data, STEPBible
(TAGNT/TBESG), MorphGNT, SBLGNT, Open Scriptures, First1KGreek, eliranwong's
Swete, any English translation of the Septuagint. Do not look Greek words up
on the web. If you are unsure of a form, say so in the row's `note` and in
your report; do not guess silently.

## Job 1: analyze forms

```sh
./scripts/gsb-literal.sh todo gen 5 6
```

Columns: `kind form count table-lemma first context`. Kinds:

- **unknown-form**: the generator has no grammar tag for the form. Add a row
  to *your book's* `gsb/literal/forms/NN-<id>.tsv`, at the end:
  `form<TAB>lemma<TAB>tag<TAB>sense<TAB>note` (sense and note may be empty).
  - At most five tab-separated columns (`check` rejects a row with more).
  - `form` exactly as in the `todo` output (Swete's spelling, accents as
    printed). Forms are matched lowercase with grave = acute and an
    enclitic's extra accent dropped, so one row covers `ὡραῖον`/`ὡραῖόν`.
  - `tag`: a Robinson code as in the NT tables (see
    `gsb/sources/nestle1904/parsing.txt` and `gsb/greek/63-john.tsv` for
    examples): `N-GSF`, `A-NPM`, `A-NSM-S` (superlative), `V-AAI-3S`,
    `V-2AAS-2P`, `V-PAP-NSM`, `V-AAN`, `P-GSM`, `P-1DS`, `R-ASN`, `D-NSF`,
    `PREP`, `CONJ`, `ADV`, `PRT-N`, `N-PRI` (indeclinable name), `N-OI`,
    `A-NUI` (indeclinable numeral). Voice: `A` active, `M` middle, `P`
    passive, `D`/`O` middle/passive deponent (rendered active).
  - `lemma`: the dictionary form, spelled as the concordance spells it (look
    it up first; see below). Use the table-lemma column when it is right.
  - `sense`: only when this form always takes a non-default sense (ἤρξατο →
    `begin`); otherwise leave empty.
  - **Ambiguous forms** (one spelling, several analyses: φάγῃ future 2sg or
    aorist subjunctive 3sg): give one row per reading, the most common in
    the Septuagint first. The generator chooses in context (preposition
    case, article agreement, subjunctive after ἵνα/ἐάν/μή); where it still
    chooses wrongly in one verse, add a word override with `(tag ...)`.
  - **Before adding**, check the form is not already analyzed in another
    file: `grep -rn '^form' gsb/literal/forms/` with the form (`check`
    reports a form in two files as an error). If another book's file has
    it, do not add it again.
  - **Proper names**: tag `N-PRI` (indeclinable) or a declined tag if Greek
    declines it; lemma = the Greek name as the text gives it in the
    nominative. Concordance sense name `name`, gloss the **traditional
    English form of that person's name in English Old Testaments** (rule 8:
    Moses, Eve, Enosh, Kenan, Methuselah), even where the Greek spelling
    differs a little (Ἐνώς, Καινάν). Only where the Greek gives a
    *different* name (Μαθουσαλά for the Hebrew Methushael, Θόβελ for
    Tubal-cain, Αἰθιοπία for Cush) does the English follow the Greek name.
    The `why` names the Greek form, the New Testament form if any (Luke 3:
    Cainan), and which case applies.
  - **Swete's misprints** kept in the transcription: analyze as the
    intended word (lemma and tag of the word Swete meant) and say so in the
    note: `Swete prints X, a misprint for Y`.
  - **Capitals** (`ΕΝ ΑΡΧΗ`, a chapter's first words): analyze as the
    accented word.
  - **Declined numerals and other neuter nominative/accusative pairs**
    (διακόσια A-NPN / A-APN): give both rows; the generator reads a neuter
    pair as accusative unless its subject rules need a subject, so the
    order of the two rows hardly matters. Fix a wrong case in one verse
    with a `(tag ...)` override only if it changes the English.
- **lemma-not-in-glosses**: add a concordance entry (below).
- **no-such-sense**: a form row or override names a sense the lemma lacks;
  fix the name or add the sense.
- A **table lemma that is wrong** (the table guessed it from a look-alike
  New Testament form, e.g. τηρήσει as the noun τήρησις): add a form row with
  the right lemma and tag; it replaces the guess.

### Concordance entries (`gsb/lexicon/glosses/NN-<letter>.scm`)

One file per initial letter of the lemma, accents ignored (`01-alpha.scm`
... `24-omega.scm`); put a new entry at its Greek alphabetical place. Each
entry: `(lemma "λέξις" (sense <name> [fields] (gloss "base" "other forms"...) (why "...")))`.

- **Check first** whether the lemma exists (search the letter file) and how
  it is used: `make gsb/uses LEMMA=λόγος`. Keep **one English word per
  lemma per sense**; a new English word for an existing lemma is a new
  sense, added **after** the existing senses, with its own `why`.
- Avoid an English word another lemma already uses for a different Greek
  word (search the glosses files for the English word); if unavoidable, say
  so in the `why`.
- The first gloss is the base form (verb: infinitive without "to", "go
  up"; noun: singular). List the inflected forms the generator will produce
  (past, participle, -s, plural) so the lint check finds them.
- A gloss may not contain an unbracketed "the" or "a" (the lint check wants
  a Greek article behind every "the"): "in front of", not "in the presence
  of"; "when", not "at the time when".
- The generator spells English forms by rule plus a built-in list of
  irregular verbs (`%irregular`); a final consonant doubles by rule in a
  one-syllable verb (blot "blotting"), and in a longer verb only if
  `%double` lists it (`%stress-initial` lists those that do not); `check`
  warns `spelling` for a longer verb in neither list: report it (do not
  edit the library). A `(verb "base" "past" "pp")` field fixes the past
  forms; for a base of several words write them in full, `(verb "go down"
  "went down" "gone down")` (the trailing words are added once; a word
  doubled inside a segment is a `check` error).
- The edit tool needs each file read before it is edited: read each letter
  file once, then make all its insertions.
- Add generator fields where needed (table in `gsb/literal/README.md`):
  `(verb "bear" "bore" "borne")` for irregular verbs not in the built-in
  list, `(plural "oxen")`, `(voice active)` (a passive used as intransitive),
  `(genitive "")`/`(dative "")` for a verb's object, `(person)` for nouns
  naming persons (son, servant, king...), `(with-preposition "εἰς" for)`,
  `(intransitive)` for verbs that take no object (motion verbs: a neuter
  plural after them is their subject), `(voice middle)` for a middle whose
  aorist/future passive is a true passive, `(apposition)` for a singular
  title noun followed by a name in apposition (ἡγεμὼν Θαιμάν "chief Teman"),
  `(dative "to")` for a verb that takes a recipient (ὁράω appear).
  Never add `(subject ...)` except for a true impersonal, with a comment.
- The `why`: what the word means, why this English, where else it occurs
  (New Testament links are welcome), and "(LXX, supplied.)" for a lemma the
  Greek table lacks.

## Generate and check

```sh
./scripts/gsb-literal.sh generate gen 5 6     # writes gsb/literal/01-gen/005.scm, 006.scm
./scripts/gsb-literal.sh check gen 5 6        # errors fail; warnings are listed
```

Fix every error. For each `ambiguous-nt-reading` warning, look at the verse:
if the borrowed reading is right, leave it (or add a form row to make the
choice explicit); if wrong, add a form row or an override.

## Job 2: review the chapters

```sh
./scripts/gsb-literal.sh show gen 5 --greek   # each verse: Greek, then English
./scripts/gsb-literal.sh explain gen.5.3      # one verse word by word: lemma, tag, sense, role, helper
```

Read **every verse** against the Greek. For each problem, fix it in the
first place that applies, then regenerate:

1. **Wrong reading of a form everywhere** (tag, lemma): fix the form row.
2. **Wrong or missing English for a lemma everywhere**: the concordance
   entry (gloss, forms, generator field).
3. **Wrong in this word only** (sense of a preposition, ὅτι "because" vs
   "that", καί "also", a tag in context, a verb's `(subject "")` because a
   relative is its subject): a word override in your book's overrides file,
   one line, with a `why`:
   `(word "gen.5.3#7" (sense because) (why "ὅτι gives the reason."))`
4. **A supplied word** only where the verse does not read without it
   (rule 16a): `(word "gen.5.3#7" (after "[is]") (why "..."))`. The test:
   can each clause be read as an English sentence? A verbless clause
   ("Name to the one Pishon", "This book of genesis", "Will not be to you
   other gods") gets `[is]`/`[was]`/`[There]`; an article never does: "In
   beginning God made" stays.
5. **The rules cannot produce acceptable English for the verse**: pin it
   with `(verse "gen.5.3" (why "...") (literal seg ...))`, written by the
   same rules (segment format in `gsb/translation/README.md`; copy the
   generated segments from `gsb/literal/NN-<id>/CCC.scm` and change only
   what must change). Rare: a pin is a missing rule.
6. **A rule fault** (the same wrong English would recur in other books:
   word order, a construction): do not work around stiffness verse by
   verse. Note it for your report (the verse, the Greek, what the rule
   should do). A merely stiff verse is never pinned, and "two or three pins
   per range" is the guide for stiffness only.
   **A verse that states something false is always fixed, with no cap**:
   a wrong actor (the subject read as the object, a vocative or a phrase
   from inside speech made the subject, a wrong person "I"/"they"), a
   reversed sense (a negation that is not in the Greek, a question asserting
   the opposite), a statement for a command. Fix it with the smallest data
   that does it (a `(tag ...)`, `(sense ...)`, `(subject ...)` or `(english
   ...)` word override), else pin the verse; say in the `why` which rule
   fault it works around. Never leave a false verse for a later pass.
   `check` warns `subject-unsure` where the rules kept the Greek order
   because they could not tell the subject: read each such verse. Also
   read every verse with one of these warnings (README "Checks"):
   - `person-unsure`: ἔλαβον, ἴδον, ἦλθον ... (first singular or third plural)
     with no cue in its sentence. Speech that began in an earlier verse is
     invisible to the rule: if the speaker says "I", fix it with
     `(tag "V-2AAI-1S")` (or the form's own tag), else `(tag "...-3P")`.
   - `inf-subject-by-rule`: the one pronoun after a transitive articular
     infinitive taken as its subject ("in her bearing"); if it is the object,
     pin or override.
   - `kyrios-check`: every κύριος is "Lord", capital or lower case (Swete's
     lower case with the article still means God: τῷ κυρίῳ, ὁ κύριος; README
     "κύριος"). The warning marks the forms a human lord is likely in
     (lower case without the article, vocative, plural, a possessor after
     it: κύριός μου, τοῦ κυρίου αὐτοῦ). Read each: if God is meant, leave
     it; if the referent is a human being (a master, owner, husband, "lord"
     said to a man), add `(word "ref#n" (sense master) (why "..."))`. Also
     read every other κύριος in narrative about masters and servants: a
     human lord with the article and no possessor (ὁ κύριος εἰς τὸν οἶκον,
     Gen 39:16) is not flagged. Never override κύριος to `(english "Lord")`
     or `(english "lord")`.

Never edit `gsb/literal/NN-<id>/*.scm` (generated), the hand files in
`gsb/translation/`, or the library.

**What to look for when reviewing** (besides senses and grammar):
- **A pronoun-less verb after καί that reads as the wrong subject.** The
  generator writes no pronoun for a verb joined by καί to the verb before
  (the Greek has none). Where the clause before names another person,
  `check` warns `kai-joined-after-another-person`; read the verse: if the
  English now says the wrong person acts (Gen 2:21 "God cast trance upon
  Adam, and slept"), put the open pronoun back:
  `(word "gen.2.21#10" (subject "he/she/it") (why "..."))`. Never a
  specific "he" or "she".
- **A pronoun given the wrong antecedent.** Third person pronouns follow
  their nearest agreeing noun in the verse (a thing gives "it"/"its", a
  person "him"/"her"/"his"). Where that noun is clearly not the referent
  (Gen 2:7 "breathed into its face", the noun being χοῦν "dust"), use the
  open form, `(english "his/its")` (or "him/it"), not the referent.
- **A verbless clause** that does not read as English: item 4 above.

**Done by rule now (third fix round): do not add overrides for these.**
γῆ before a country's name is "land" (γῆ Αἰγύπτου "land of Egypt");
"the Lord our/my/their God" (Κύριος ὁ θεὸς ἡμῶν) and "the Lord God of
Israel"; a verbless τί/τίνος question gets "[is]"/"[are]" (Τί τοῦτο; "What
[is] this?"), so never add another; the intensive αὐτός beside or with a
first/second person ("you yourselves", ὑμῖν αὐτοῖς "to you yourselves") and
ἑαυτοῖς with a second person verb ("yourselves"); oaths ("swear by God",
κατ’ ἐμαυτοῦ "by myself"); καὶ ἔσται ὅταν "and it will be whenever"; a
dative relative that is not attracted is "to whom/which"; τὰ πάντα "all the
[things]"; χρυσίον καθαρόν "pure gold" (a noun's `(with-adjective ...)`
field: use it for other fixed adjective senses). An old override that
supplied one of these now doubles it ("[is] [is]"): delete it. In
instructions (verses whose finite verbs are all second person) a thing
pronoun may take its antecedent from the verse before ("you will gild over
it"); read those.

**What to expect in legal and cultic chapters** (Leviticus, Numbers,
Deuteronomy; from a look-ahead at Lev 1 and Deut 6):
- Third person pronouns: the offerer is usually named verses back, so
  αὐτοῦ/αὐτῷ in "his gift", "acceptable to him" take the nearest noun
  (τὸ δῶρον αὐτοῦ after ὁλοκαύτωμα: "its gift"; δεκτὸν αὐτῷ after τοῦ
  μαρτυρίου: "to it"). Expect many `(english "his/its")` / `(english
  "him/it")` overrides; a whole-chapter pattern is worth reporting as a rule
  fault rather than overriding forty times.
- Verbless ἐάν protases (Ἐὰν ὁλοκαύτωμα τὸ δῶρον αὐτοῦ ...) read as
  fragments: supply `[is]` by override where a clause does not read.
- κάρπωμά ἐστιν, ἅγιόν ἐστιν: an anarthrous neuter noun opening its clause
  before εἰμί, with nothing after it but a dative, is the predicate: "he/she/it
  is fruit offering" (by rule). With a genitive after (κάρπωμά ἐστιν θυσίας)
  the rule does not fire and θυσίας may need `(tag "N-GSF")`.
- Lower-case τῷ κυρίῳ in the formula ὀσμὴ εὐωδίας τῷ κυρίῳ is "to the Lord"
  by rule (README "κύριος"); no override. Only a human κύριος needs data
  (sense `master`).
- The future as command ("you will not ...") is rendered as a future, as the
  Greek has it; οὐ before a form that could be imperative is read as the
  indicative (a form row with both readings is needed, imperative first).
- Repeated articles (τὰ ξύλα τὰ ἐπὶ τοῦ πυρὸς τὰ ὄντα ἐπὶ τοῦ θυσιαστηρίου)
  come out "the [things] being upon": stiff, not false; leave them.
- κατὰ μέλη "according to limbs" and similar distributive κατά: a `(sense
  ...)` override where the sense differs; ὃν τρόπον "which manner" is stiff.
- μή after a command to take heed (πρόσεχε σεαυτῷ μὴ ἐπιλάθῃ) is "lest" by
  rule; μή + a nominative participle + subjunctive is "lest" too.

**Acceptable** means: every Greek word is translated with the right sense
and grammatical role (subject, object, case), nothing the Greek leaves open
is resolved (rule 9), and the verse can be read as English, however stiff.
**Do not** "fix", by override, what rule 16a makes deliberately stiff: no
article or linking verb for smoothness; never "he", "she" or "it" chosen by
meaning where the generator writes "he/she/it", and never "his" or "its"
where it writes "his/its"; "and said" with no pronoun after καί is right.

## Shared files and conflicts

- Your book's `forms/NN-<id>.tsv` and `overrides/NN-<id>.scm`: append at the
  end; other agents on other chapters of the same book append too, so keep
  each addition a block of whole lines and do not reorder existing lines.
  One form per line; two overrides of one word, or two pins of one verse,
  are a load error: merge their items into one form. Word overrides on a
  pinned verse do nothing (the pin is copied as written).
- Lettered chapters (Esther's additions A-F): give the letter as the
  chapter, `./scripts/gsb-literal.sh generate esth A`; the file is
  `gsb/literal/17-esth/A.scm`.
- Concordance letter files: insert new entries at their alphabetical place;
  never reformat, move or rewrite other entries; change an existing entry
  only by adding a sense after its senses or a gloss form/field, never by
  changing its `why`.
- `gsb/literal/forms/00-common.tsv` and `gsb/literal/phrases.scm` are shared
  by all books: add to them only for a form or phrase that is common in many
  books, and mention it in your report.
- If two files end up analyzing one form, or a lemma is listed twice, the
  checks fail; fix by keeping the earlier one.

## Finish

```sh
./scripts/gsb-literal.sh check gen 5 6     # must end "data and generated text pass"
make gsb/lint                               # must pass
make test                                   # must pass
```

Report: the chapters done; counts of form rows, new lemmas, new senses,
overrides and pinned verses added; warnings left and why; rule faults found
(verse, Greek, what the rule should do); open questions for the owner (gloss
choices, names); anything you were unsure of. Quote the generated text of
the chapters (`show <id> <chapter>`) if asked.
