-- Greek Source Bible (GSB) database: schema and data dictionary.
--
-- One SQLite file holds the whole project: the Greek text in two verse
-- numberings, every word with its lemma, Strong's number and grammar tag,
-- the lexicon, our concordance of English glosses with the reasoning for
-- each, the translation and its word-by-word alignment, the translation
-- notes, and every decision made while transcribing Swete's Septuagint from
-- the page scans. Every page of /bible/versions/gsb/ is rendered from it.
--
-- It is built by `make gsb/db` (scripts/gsb-db.scm) from the text files in
-- the repository's gsb/ directory, which are where edits are made; the same
-- files always give the same database. Dedicated to the public domain (CC0
-- 1.0); no attribution needed.
--
-- Conventions:
--   * A verse is addressed by `ref`, '<book id>.<chapter>.<verse>':
--     'gen.1.1', 'john.3.16'. Verse labels can be lettered or combined as
--     Swete prints them ('gen.31.48a', 'exod.37.4-5'), so `verse` is text.
--   * A word is addressed by (ref, n), n counting from 1 within the verse.
--   * Empty values are NULL. Text is UTF-8, Unicode NFC.
--   * Flags and lists of forms are JSON arrays: use json_each().
--   * Rows keep the order of their source files; `id`/`ord` columns record it.

-- Facts about the dataset as a whole, one row per key: name, license,
-- license_statement, description, updated (the latest transcription date),
-- schema (this file), resource_gaps (markdown), readme_greek and
-- readme_translation (the format documents, markdown).
CREATE TABLE meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Each pinned public-domain or CC0 source, with its README: upstream URL,
-- pinned version and the upstream public-domain or CC0 statement.
CREATE TABLE sources (
  name   TEXT PRIMARY KEY,  -- 'swete', 'nestle1904', 'tr', 'rp', 'dodson', 'strongs'
  readme TEXT NOT NULL      -- markdown
);

-- The books in our order: conventional Septuagint order for the Old
-- Testament, then the usual New Testament order.
CREATE TABLE books (
  ord              INTEGER PRIMARY KEY,  -- 1, 2, ... in book order
  nn               TEXT NOT NULL,        -- file prefix: '01'
  id               TEXT NOT NULL UNIQUE, -- 'gen', '3kgdms', 'dan-th'
  english          TEXT NOT NULL,        -- 'Genesis', '3 Kingdoms (1 Kings)'
  greek            TEXT NOT NULL,        -- 'Γένεσις'
  testament        TEXT NOT NULL,        -- 'OT' or 'NT'
  deuterocanonical INTEGER NOT NULL,     -- 1 for books outside the 39-book Protestant Old Testament
  role             TEXT NOT NULL,        -- 'main', or 'comparison' (Theodotion's Daniel, Susanna, Bel; Sinaiticus Tobit)
  source           TEXT,                 -- 'swete', 'nestle1904'
  notes            TEXT,
  chapters         INTEGER,              -- the book's chapter total, once verified
  slug             TEXT NOT NULL         -- verse anchor prefix on the site: 'genesis' in #genesis-1-1
);

-- One row per verse, in printed order. LXX verses use the common (English)
-- numbering; `swete_ref` keeps Swete's own number where the verse begins.
CREATE TABLE verses (
  id         INTEGER PRIMARY KEY,  -- printed order across the whole Bible
  ref        TEXT NOT NULL UNIQUE, -- 'gen.1.1'
  book       TEXT NOT NULL REFERENCES books(id),
  chapter    INTEGER NOT NULL,     -- a number; Esther's Greek additions are the letters 'A'-'F' (stored as text, ref 'esth.A.1')
  verse      TEXT NOT NULL,        -- '1', '48a', '4-5', '34,36b'
  swete_ref  TEXT,                 -- LXX: Swete's own chapter:verse ('3:1' for common 2:25)
  leaf_first INTEGER,              -- LXX: scan leaf and printed line where the verse starts ...
  line_first INTEGER,
  leaf_last  INTEGER,              -- ... and where it ends (see transcription_pages)
  line_last  INTEGER,
  printed    TEXT,                 -- LXX: the verse exactly as Swete prints it (capitals, brackets)
  greek      TEXT NOT NULL         -- the words as published, with punctuation (words.pre || word || post)
);
CREATE INDEX verses_book ON verses(book, chapter);

-- One row per Greek word.
CREATE TABLE words (
  ref    TEXT NOT NULL REFERENCES verses(ref),
  n      INTEGER NOT NULL,  -- 1-based position in the verse; restored TR words are numbered in place
  book   TEXT NOT NULL,
  pre    TEXT,              -- punctuation before the word: '(' '“'
  word   TEXT NOT NULL,     -- elision written U+2019: 'κατ’'
  post   TEXT,              -- punctuation after: ',' '.' '·' ';'
  lemma  TEXT,              -- dictionary form, where known (LXX: from the reading in morph when there is one)
  strong TEXT,              -- 'G1'..'G5624' (New Testament vocabulary only)
  morph  TEXT,              -- Robinson parsing code: 'V-PAI-3S'. NT: Nestle 1904's. LXX: the reading
                            -- the scripted literal layer chose (form_analyses, else the same form's
                            -- New Testament reading, chosen in context; see gsb/literal/README.md)
  flags  TEXT,              -- JSON array, see below
  PRIMARY KEY (ref, n)
) WITHOUT ROWID;
-- Flags:
--   tr        NT: a longer Textus Receptus reading restored into the Nestle 1904 base
--   tr-verse  NT: the whole verse comes from the TR (also tr)
--   accent?   NT: restored TR word whose accents could not be recovered
--   punct     NT: restored TR word given punctuation from the base word before it
--   decap     LXX: Swete's unaccented capitals restored to an accented form
--   caps      LXX: still in Swete's capitals (no unambiguous accented form)
--   lemma?    LXX: lemma guessed (several candidates, or matched without accents)
--   siglum    LXX: an editorial siglum was removed here
--   bracket   LXX: square brackets (letters lost in the manuscript) removed from this word

-- Strong's Greek dictionary with Dodson's glosses.
CREATE TABLE lexicon (
  strong            TEXT PRIMARY KEY,  -- 'G746'
  lemma             TEXT,              -- Nestle 1904's lemma for the number, else Strong's headword
  strongs_headword  TEXT,
  gloss             TEXT,              -- Dodson, brief
  definition        TEXT,              -- Dodson's longer definition, else Strong's
  definition_source TEXT               -- 'dodson' or 'strongs'
);

-- Our concordance: one English gloss per Greek lemma per sense, each with
-- the reasoning. The literal layer is checked against it by script.
CREATE TABLE glosses (
  lemma    TEXT NOT NULL,
  sense    TEXT NOT NULL,     -- the sense's name, unique within the lemma: 'beginning', 'rule'
  ord      INTEGER NOT NULL,  -- 1 = the lemma's default sense
  gloss    TEXT NOT NULL,     -- the gloss; '' = English leaves the word unrendered
  forms    TEXT NOT NULL,     -- JSON array: the gloss and its accepted forms ('was', 'were' ...)
  readable TEXT,              -- the readable layer's word, where it differs from the gloss
  why      TEXT NOT NULL,     -- the reasoning
  PRIMARY KEY (lemma, sense)
);

-- Words the readable layer does not use, with the replacement and the reason.
CREATE TABLE readable_avoid (
  word TEXT PRIMARY KEY,
  use  TEXT NOT NULL,
  why  TEXT NOT NULL
);

-- The English of each translated verse, one row per layer:
-- 'literal' (hyper-literal: one gloss per lemma and sense, supplied words in
-- [brackets]) and 'readable'.
CREATE TABLE translation (
  ref    TEXT NOT NULL REFERENCES verses(ref),
  layer  TEXT NOT NULL,  -- 'literal' or 'readable'
  status TEXT NOT NULL,  -- 'draft' (drafted, AI-assisted) or 'reviewed' (by the owner)
  text   TEXT NOT NULL,
  source TEXT,           -- 'generated' (gsb/literal/: the scripted literal layer, rule 16a) or 'hand' (gsb/translation/)
  PRIMARY KEY (ref, layer)
);

-- The English of a layer cut into segments, each aligned to the Greek words
-- it translates (translation_words). Joining a verse's segments with single
-- spaces in `seg` order gives translation.text. The readable layer has
-- segments only where it is aligned.
CREATE TABLE translation_segments (
  ref      TEXT NOT NULL,
  layer    TEXT NOT NULL,
  seg      INTEGER NOT NULL,  -- 1, 2, ... in English order
  clause   INTEGER,           -- literal: clause number within the verse (from 0), NULL outside a clause
  text     TEXT NOT NULL,     -- English, [supplied] words in brackets
  supplied INTEGER NOT NULL,  -- 1 when no Greek word stands behind the segment
  PRIMARY KEY (ref, layer, seg)
);

-- Which Greek words each segment translates. A word has one own segment
-- (cont = 0); where English needs other words inside one Greek word's
-- rendering, later segments continue it (cont = 1: 'sent him out').
CREATE TABLE translation_words (
  ref           TEXT NOT NULL,
  layer         TEXT NOT NULL,
  seg           INTEGER NOT NULL,
  pos           INTEGER NOT NULL,  -- order within the segment, from 1
  n             INTEGER NOT NULL,  -- the Greek word (words.ref, words.n)
  cont          INTEGER NOT NULL,  -- 1: this segment continues word n, whose own segment comes earlier
  lemma         TEXT,              -- literal own word: the lemma used (ours where the table has none or a wrong one)
  sense         TEXT,              -- literal own word: the concordance sense used (glosses.sense)
  default_sense INTEGER,           -- literal own word: 1 when the file left the sense to the lemma's default
  PRIMARY KEY (ref, layer, seg, pos)
);
CREATE INDEX translation_words_word ON translation_words(ref, n);

-- The data behind the scripted literal layer (gsb/literal/README.md). The
-- English in `translation` with source 'generated' is made from these, the
-- Greek and the concordance by scripts/gsb-literal.scm; never edited by hand.

-- Our analyses of Septuagint word forms: one row per reading, the first
-- reading of a form (lowest ord) its default. A form with no row borrows
-- the readings the same form has in the New Testament tables.
CREATE TABLE form_analyses (
  form  TEXT NOT NULL,     -- as Swete prints it
  ord   INTEGER NOT NULL,  -- file order across gsb/literal/forms/*.tsv
  lemma TEXT NOT NULL,
  tag   TEXT NOT NULL,     -- Robinson code, as words.morph
  sense TEXT,              -- concordance sense for this form (glosses.sense), when fixed
  note  TEXT,
  file  TEXT NOT NULL,     -- 'gsb/literal/forms/01-gen.tsv'
  PRIMARY KEY (ord)
);
CREATE INDEX form_analyses_form ON form_analyses(form);

-- Hand-kept exceptions for one word (n set) or one whole verse (n NULL,
-- kind 'verse': the verse's literal segments are taken as written).
CREATE TABLE literal_overrides (
  ord     INTEGER PRIMARY KEY,  -- file order
  ref     TEXT NOT NULL,
  n       INTEGER,
  kind    TEXT NOT NULL,        -- 'word' or 'verse'
  lemma   TEXT,                 -- word: the lemma to use
  tag     TEXT,                 -- word: the grammar tag to use
  sense   TEXT,                 -- word: the concordance sense to use
  english TEXT,                 -- word: replaces the word's English
  before  TEXT,                 -- word: supplied [words] before it
  after   TEXT,                 -- word: supplied [words] after it
  subject TEXT,                 -- word (a verb): the pronoun of its ending ('' for none)
  why     TEXT NOT NULL,
  file    TEXT NOT NULL
);
CREATE INDEX literal_overrides_ref ON literal_overrides(ref, n);

-- Fixed multi-word phrases rendered as one segment (ἀνὰ μέσον "between").
CREATE TABLE literal_phrases (
  ord     INTEGER PRIMARY KEY,
  lemmas  TEXT NOT NULL,  -- JSON array of consecutive lemmas
  senses  TEXT NOT NULL,  -- JSON array: each word's concordance sense
  english TEXT NOT NULL,
  tag     TEXT,           -- grammar of the whole, else the phrase's noun's
  why     TEXT NOT NULL
);

-- Greek words deliberately left out of the literal layer, with the reason.
CREATE TABLE untranslated (
  ref    TEXT NOT NULL,
  n      INTEGER NOT NULL,
  reason TEXT NOT NULL,
  PRIMARY KEY (ref, n)
);

-- Translation notes: decisions and observations, markdown. The scope is
-- given by which columns are set: book only (a book note), book and chapter
-- (a chapter note), ref (a verse note), ref and n (a note on one word).
CREATE TABLE notes (
  id       INTEGER PRIMARY KEY,  -- file order
  book     TEXT NOT NULL,
  chapter  INTEGER,
  ref      TEXT,
  n        INTEGER,
  markdown TEXT NOT NULL
);

-- Our transcription of Swete, one row per scan leaf (page image) we have a
-- page file for. `text` is the page file itself: one printed line per line,
-- with markers ({C3} chapter, {7} Swete's verse, {=2:25} common verse,
-- {P} paragraph, {S} poetry) as documented in sources.readme for 'swete'.
CREATE TABLE transcription_pages (
  book         TEXT NOT NULL,
  leaf         INTEGER NOT NULL,  -- archive.org leaf number
  scan         TEXT NOT NULL,     -- archive.org identifier
  volume       INTEGER,
  printed_page TEXT,              -- Swete's page number
  box          TEXT,              -- main-text box in page pixels: 'y0 y1 x0 x1'
  done_date    TEXT,              -- 'YYYY-MM-DD' when finished and validated
  method       TEXT,              -- method version: 'swete-2'
  status       TEXT NOT NULL,     -- 'done' or 'in progress'
  in_tables    INTEGER NOT NULL,  -- 1 when the page is in the published verse tables
  text         TEXT NOT NULL,
  PRIMARY KEY (book, leaf)
);

-- Every decision made while transcribing: each token where the three readings
-- of a page disagreed or a mandatory check applied. Reading A is
-- archive.org's OCR, B a fresh Tesseract pass, C our own reading of the image.
CREATE TABLE transcription_decisions (
  id        INTEGER PRIMARY KEY,  -- file order
  book      TEXT NOT NULL,
  scan      TEXT NOT NULL,
  leaf      INTEGER NOT NULL,
  line      INTEGER NOT NULL,     -- printed line on the leaf, from 1
  reading_a TEXT,
  reading_b TEXT,
  reading_c TEXT,               -- our first reading
  chosen    TEXT,
  basis     TEXT                -- why: an OCR error class (R0-R7) or what the image shows
);
CREATE INDEX transcription_decisions_leaf ON transcription_decisions(book, leaf, line);

-- Per book and Swete chapter: scan, leaves, printed pages, dates, methods.
CREATE TABLE transcription_provenance (
  book          TEXT NOT NULL,
  chapter       INTEGER NOT NULL,  -- Swete's chapter
  scan          TEXT NOT NULL,
  leaves        TEXT NOT NULL,     -- '33-35'
  printed_pages TEXT,
  date          TEXT,
  method        TEXT
);

-- Each book's volume, scan and leaf range in Swete.
CREATE TABLE transcription_leaves (
  book       TEXT PRIMARY KEY,
  volume     INTEGER NOT NULL,
  scan       TEXT NOT NULL,
  first_leaf INTEGER NOT NULL,
  last_leaf  INTEGER,
  step       INTEGER NOT NULL,  -- 2 where two texts face each other (Daniel)
  note       TEXT
);

-- Where Swete's parenthesized numbers (Hebrew chapter division) are converted
-- to the English one: Hebrew range `hebrew_from`..`hebrew_to` within one
-- chapter starts at English `english`.
CREATE TABLE versification (
  book        TEXT NOT NULL,
  hebrew_from TEXT NOT NULL,  -- 'c:v'
  hebrew_to   TEXT NOT NULL,
  english     TEXT NOT NULL
);

-- Every difference between Nestle 1904 and the Textus Receptus, by verse.
-- Kinds 'insert' and 'verse' were restored into the text (flag tr); 'subst',
-- 'subst-split', 'order', 'tr-omits', 'moved' and 'moved-verse' keep the base.
CREATE TABLE nt_variants (
  id         INTEGER PRIMARY KEY,
  ref        TEXT NOT NULL,
  kind       TEXT NOT NULL,
  nestle1904 TEXT,
  tr         TEXT
);

-- Build reports.
CREATE TABLE lxx_coverage (        -- lemma and Strong's coverage per LXX book
  book TEXT PRIMARY KEY, status TEXT, tokens INTEGER, with_lemma INTEGER, lemma_pct REAL,
  with_strong INTEGER, strong_pct REAL, types INTEGER, types_with_lemma INTEGER, type_pct REAL
);
CREATE TABLE lxx_unmatched_forms ( -- the commonest LXX forms with no lemma yet
  rank INTEGER PRIMARY KEY, form TEXT, count INTEGER
);
CREATE TABLE lxx_capitals (        -- Swete's unaccented capitals and how each was resolved
  ref TEXT, n INTEGER, swete TEXT, status TEXT, restored TEXT
);
CREATE TABLE nt_unaccented (       -- restored TR words still to be accented by hand
  ref TEXT, n INTEGER, word TEXT, strong TEXT
);

-- Full-text search over every verse: Greek as printed, Greek without accents
-- or breathings (lowercase, final sigma as σ), the verse's lemmas, and its
-- English (both layers). Its rowid is verses.id; it keeps only the index, not
-- a copy of the text, so join verses for the text:
--   SELECT v.ref, v.greek FROM search JOIN verses v ON v.id = search.rowid
--   WHERE search MATCH 'greek_plain: αρχη';
CREATE VIRTUAL TABLE search USING fts5(
  greek, greek_plain, lemmas, english, content=''
);

-- A verse with its Greek and English side by side.
CREATE VIEW verse_text AS
SELECT v.ref, v.book, v.chapter, v.verse, v.greek,
       l.text AS literal, r.text AS readable, l.status
FROM verses v
LEFT JOIN translation l ON l.ref = v.ref AND l.layer = 'literal'
LEFT JOIN translation r ON r.ref = v.ref AND r.layer = 'readable';

-- How the generated literal layer was made, per verse: whether pinned and how
-- many words carry an override (see literal_overrides).
CREATE VIEW literal_verse_data AS
SELECT t.ref,
       EXISTS (SELECT 1 FROM literal_overrides o WHERE o.ref = t.ref AND o.kind = 'verse') AS pinned,
       (SELECT count(*) FROM literal_overrides o WHERE o.ref = t.ref AND o.kind = 'word') AS word_overrides
FROM translation t
WHERE t.layer = 'literal' AND t.source = 'generated';

-- Every Greek word with the lemma and sense it is translated with and its
-- English in the literal layer (pieces of one word's English joined by ' … ').
-- Words not yet translated have NULL english.
CREATE VIEW word_english AS
SELECT w.ref, w.n, w.word, coalesce(o.lemma, w.lemma) AS lemma, w.strong, w.morph,
       o.sense,
       (SELECT group_concat(s.text, ' … ')
          FROM (SELECT s.text FROM translation_words t
                JOIN translation_segments s USING (ref, layer, seg)
                WHERE t.ref = w.ref AND t.n = w.n AND t.layer = 'literal'
                ORDER BY t.cont, t.seg) s) AS english
FROM words w
LEFT JOIN translation_words o
  ON o.ref = w.ref AND o.n = w.n AND o.layer = 'literal' AND o.cont = 0;

-- Every transcription decision on the lines a verse is printed on.
CREATE VIEW verse_decisions AS
SELECT v.ref, d.*
FROM verses v
JOIN transcription_decisions d
  ON d.book = v.book
 AND (d.leaf > v.leaf_first OR (d.leaf = v.leaf_first AND d.line >= v.line_first))
 AND (d.leaf < v.leaf_last OR (d.leaf = v.leaf_last AND d.line <= v.line_last));

-- Progress per book, in verses, in book order: Greek transcribed, literal
-- English, readable English, and readable verses accepted by the owner
-- (status 'reviewed'). Verse totals are not known in advance, so a book's
-- transcription is complete when all its chapters (books.chapters) are present.
CREATE VIEW progress AS
SELECT b.ord, b.id AS book, b.english, b.testament, b.role,
       (SELECT count(*) FROM verses v WHERE v.book = b.id) AS transcribed,
       (SELECT count(DISTINCT v.chapter) FROM verses v WHERE v.book = b.id) AS chapters_transcribed,
       b.chapters,
       coalesce(b.chapters <= (SELECT count(DISTINCT v.chapter) FROM verses v WHERE v.book = b.id), 0) AS transcription_complete,
       (SELECT count(*) FROM translation t JOIN verses v ON v.ref = t.ref
         WHERE v.book = b.id AND t.layer = 'literal') AS literal,
       (SELECT count(*) FROM translation t JOIN verses v ON v.ref = t.ref
         WHERE v.book = b.id AND t.layer = 'readable') AS readable,
       (SELECT count(*) FROM translation t JOIN verses v ON v.ref = t.ref
         WHERE v.book = b.id AND t.layer = 'readable' AND t.status = 'reviewed') AS accepted
FROM books b;

-- The same counts summed for the Old Testament ('OT'), the New ('NT') and
-- the whole Bible ('all'), with how many books have any Greek yet.
CREATE VIEW progress_totals AS
SELECT scope, books, books_started, transcribed, literal, readable, accepted FROM (
  SELECT 1 AS o, testament AS scope, count(*) AS books, sum(transcribed > 0) AS books_started,
         sum(transcribed) AS transcribed, sum(literal) AS literal, sum(readable) AS readable, sum(accepted) AS accepted
  FROM progress WHERE testament = 'OT'
  UNION ALL
  SELECT 2, testament, count(*), sum(transcribed > 0), sum(transcribed), sum(literal), sum(readable), sum(accepted)
  FROM progress WHERE testament = 'NT'
  UNION ALL
  SELECT 3, 'all', count(*), sum(transcribed > 0), sum(transcribed), sum(literal), sum(readable), sum(accepted)
  FROM progress)
ORDER BY o;
