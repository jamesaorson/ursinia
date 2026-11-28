;; Copyright (C) 2026
;;
;; The Greek Source Bible database (gsb/schema.sql): building it from the text
;; files under gsb/ and querying it. Both go through the `sqlite3` command-line
;; program (no Guile SQLite module needed): the builder writes SQL text into
;; one `sqlite3` process inside one transaction; queries read `sqlite3 -ascii`
;; output (unit separator between columns, record separator between rows, so
;; tabs and newlines in values survive).
;;
;; Paths are relative to the working directory, which must hold gsb/ (the repo
;; root, or a test fixture tree). Inputs that are missing simply load no rows.

(define-module (scripts lib gsb-db)
  #:use-module (scripts lib gsb)
  #:use-module (scripts lib gsb-translation)
  #:use-module (scripts lib gsb-literal)
  #:use-module (scripts lib swete)
  #:use-module (scripts lib bible)
  #:use-module (ice-9 format)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 textual-ports)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (json
            sqlite3-problem
            sql-query
            build-database!))

;;; ---------------------------------------------------------------------------
;;; JSON text (for flags and gloss forms here, page data in gsb-site.scm)
;;; ---------------------------------------------------------------------------

(define (json x)
  "JSON text for X: strings, numbers, #t/#f/'null, vectors (arrays) and alists
with string keys (objects)."
  (cond
   ((string? x)
    (string-append
     "\""
     (string-concatenate
      (map (lambda (c)
             (cond ((char=? c #\") "\\\"")
                   ((char=? c #\\) "\\\\")
                   ((char<? c #\space) (format #f "\\u~4,'0x" (char->integer c)))
                   (else (string c))))
           (string->list x)))
     "\""))
   ((number? x) (number->string x))
   ((symbol? x) (if (eq? x 'null) "null" (json (symbol->string x))))
   ((eq? x #t) "true")
   ((eq? x #f) "false")
   ((vector? x) (string-append "[" (string-join (map json (vector->list x)) ",") "]"))
   ((null? x) "{}")
   (else (string-append "{" (string-join (map (lambda (p) (string-append (json (car p)) ":" (json (cdr p)))) x) ",") "}"))))

;;; ---------------------------------------------------------------------------
;;; sqlite3
;;; ---------------------------------------------------------------------------

(define %install "install sqlite3 3.38 or newer: brew install sqlite / apt-get install sqlite3")

(define (run-read . args)
  "Output of the command ARGS (a list of strings), and its exit status."
  (let* ((port (apply open-pipe* OPEN_READ args)))
    (set-port-encoding! port "UTF-8")
    (let* ((out (get-string-all port))
           (status (close-pipe port)))
      (values out status))))

(define (sqlite3-problem)
  "#f when a usable sqlite3 is on PATH, else what to do about it."
  (catch #t
    (lambda ()
      (call-with-values (lambda () (run-read "sqlite3" "-version"))
        (lambda (out status)
          (let ((m (string-match "^([0-9]+)\\.([0-9]+)" out)))
            (cond
             ((or (not (zero? (or (status:exit-val status) 1))) (not m))
              (format #f "sqlite3 not found on PATH; ~a" %install))
             ((let ((major (string->number (match:substring m 1)))
                    (minor (string->number (match:substring m 2))))
                (or (< major 3) (and (= major 3) (< minor 38))))
              (format #f "sqlite3 ~a is too old (JSON functions need 3.38); ~a"
                      (string-trim-both out) %install))
             (else
              (call-with-values
                  (lambda () (run-read "sqlite3" ":memory:" "CREATE VIRTUAL TABLE t USING fts5(x);"))
                (lambda (_ status)
                  (and (not (zero? (or (status:exit-val status) 1)))
                       (format #f "this sqlite3 has no FTS5 full-text search; ~a" %install))))))))))
    (lambda _ (format #f "sqlite3 not found on PATH; ~a" %install))))

(define (sql-query db sql)
  "Rows of SQL run against the database file DB: a list of lists of strings
(NULL reads as \"\")."
  (call-with-values (lambda () (run-read "sqlite3" "-bail" "-noheader" "-ascii" db sql))
    (lambda (out status)
      (unless (zero? (or (status:exit-val status) 1))
        (error "sqlite3 query failed" db sql))
      (map (lambda (row) (string-split row #\x1f))
           (remove string-null? (string-split out #\x1e))))))

(define (sql x)
  "SQL literal for X: #f and \"\" are NULL ('empty is the empty string),
numbers as they are, strings quoted."
  (cond ((or (not x) (equal? x "")) "NULL")
        ((eq? x 'empty) "''")
        ((number? x) (number->string x))
        ((symbol? x) (sql (symbol->string x)))
        (else (string-append "'" (regexp-substitute/global #f "'" x 'pre "''" 'post) "'"))))

(define (text s) (if (string-null? s) 'empty s))

(define (insert port table columns rows)
  "INSERT ROWS (lists of values) into TABLE, 500 rows per statement."
  (let loop ((rows rows) (left (length rows)))
    (unless (null? rows)
      (let ((k (min 500 left)))
        (format port "INSERT INTO ~a(~a) VALUES~%~a;~%" table (string-join columns ",")
                (string-join (map (lambda (r) (string-append "(" (string-join (map sql r) ",") ")")) (list-head rows k)) ",\n"))
        (loop (list-tail rows k) (- left k))))))

;;; ---------------------------------------------------------------------------
;;; Reading inputs
;;; ---------------------------------------------------------------------------

(define (slurp path) (if (file-exists? path) (call-with-input-file path get-string-all) ""))

(define (tsv-rows path)
  "Data rows of a TSV file (header dropped), each a list of fields; none if absent."
  (if (file-exists? path) (map split-tab (cdr (read-lines path))) '()))

(define (pad row n) (take (append row (make-list n "")) n))

(define (insert-tsv port table columns path)
  (insert port table columns (map (lambda (r) (pad r (length columns))) (tsv-rows path))))

(define (dir-files dir rx)
  "Sorted names in DIR matching the regexp RX (none if DIR is absent)."
  (sort (or (scandir dir (lambda (f) (string-match rx f))) '()) string<?))

;; Anchors: the same #<book>-<chapter>-<verse> ids as the KJV and BSB pages
;; wherever the book is the same book; the GSB id otherwise.
(define %shared-books
  '(("gen" . "Genesis") ("exod" . "Exodus") ("lev" . "Leviticus") ("num" . "Numbers")
    ("deut" . "Deuteronomy") ("josh" . "Joshua") ("judg" . "Judges") ("ruth" . "Ruth")
    ("1kgdms" . "1 Samuel") ("2kgdms" . "2 Samuel") ("3kgdms" . "1 Kings") ("4kgdms" . "2 Kings")
    ("1chr" . "1 Chronicles") ("2chr" . "2 Chronicles") ("esth" . "Esther") ("job" . "Job")
    ;; ponytail: Psalms and Jeremiah keep the shared slug although Swete's
    ;; numbering differs (LXX Ps 9 = Heb 9-10; Jeremiah's order); revisit with
    ;; the versification decision (ursinia-vff.10).
    ("ps" . "Psalm") ("prov" . "Proverbs") ("eccl" . "Ecclesiastes") ("song" . "Song of Solomon")
    ("isa" . "Isaiah") ("jer" . "Jeremiah") ("lam" . "Lamentations") ("ezek" . "Ezekiel")
    ("dan" . "Daniel") ("hos" . "Hosea") ("joel" . "Joel") ("amos" . "Amos") ("obad" . "Obadiah")
    ("jonah" . "Jonah") ("mic" . "Micah") ("nah" . "Nahum") ("hab" . "Habakkuk")
    ("zeph" . "Zephaniah") ("hag" . "Haggai") ("zech" . "Zechariah") ("mal" . "Malachi")
    ("matt" . "Matthew") ("mark" . "Mark") ("luke" . "Luke") ("john" . "John") ("acts" . "Acts")
    ("rom" . "Romans") ("1cor" . "1 Corinthians") ("2cor" . "2 Corinthians") ("gal" . "Galatians")
    ("eph" . "Ephesians") ("phil" . "Philippians") ("col" . "Colossians")
    ("1thess" . "1 Thessalonians") ("2thess" . "2 Thessalonians") ("1tim" . "1 Timothy")
    ("2tim" . "2 Timothy") ("titus" . "Titus") ("phlm" . "Philemon") ("heb" . "Hebrews")
    ("jas" . "James") ("1pet" . "1 Peter") ("2pet" . "2 Peter") ("1john" . "1 John")
    ("2john" . "2 John") ("3john" . "3 John") ("jude" . "Jude") ("rev" . "Revelation")))

(define (book-anchor id)
  (let ((name (assoc-ref %shared-books id)))
    (if name (book-slug (book-by-display-name name)) id)))

(define (markdown-section text heading)
  "The body of the `## HEADING` section of markdown TEXT, or \"\"."
  (let ((start (string-contains text (string-append "\n## " heading))))
    (if (not start)
        ""
        (let* ((body (+ 1 (or (string-index text #\newline (+ start 1)) (string-length text))))
               (end (or (string-contains text "\n## " body) (string-length text))))
          (string-trim-both (substring text (min body end) end))))))

;;; ---------------------------------------------------------------------------
;;; Swete page files: where each verse is printed, and Swete's own number
;;; ---------------------------------------------------------------------------

(define %swete "gsb/sources/swete")

(define (swete-leaves)
  "leaves.tsv as ((book volume scan first last step note) ...)."
  (map (lambda (r) (pad r 7)) (tsv-rows (string-append %swete "/leaves.tsv"))))

(define (book-pages book)
  "((leaf volume . page) ...) for every page file of BOOK, by leaf."
  (let ((dir (string-append %swete "/pages/" book)))
    (map (lambda (f)
           (let ((m (string-match "^v([0-9]+)-([0-9]+)\\.txt$" f)))
             (cons* (string->number (match:substring m 2)) (string->number (match:substring m 1))
                    (parse-page (slurp (string-append dir "/" f))))))
         (dir-files dir "^v[0-9]+-[0-9]+\\.txt$"))))

(define (leading-run pages first step)
  "The leaves of PAGES that make up the verse tables: the run of done pages
from the book's first leaf (as `gsb-swete.sh merge` takes them)."
  (let loop ((ps pages) (want first) (acc '()))
    (match ps
      (((leaf _ . page) . rest)
       (if (and (= leaf want) (page-header page "done")) (loop rest (+ want step) (cons leaf acc)) (reverse acc)))
      (() (reverse acc)))))

(define (versification-ranges book)
  "BOOK's versification.tsv rows as (chapter from to english-chapter english-first)."
  (filter-map
   (match-lambda
     ((b from to english . _)
      (and (string=? b book)
           (match (map (lambda (s) (map string->number (string-split s #\:))) (list from to english))
             (((c f) (_ t) (ec ev)) (list c f t ec ev))
             (_ #f))))
     (_ #f))
   (tsv-rows (string-append %swete "/versification.tsv"))))

(define (verse-locations book pages run)
  "Hash \"chapter.verse\" (common numbering) -> (swete-ref leaf-first line-first
leaf-last line-last) from the page files of the leaves in RUN."
  (let* ((hits
          ;; (c v (swete-ref leaf line)) for every stretch of text, in order.
          (let loop ((ps (filter (lambda (p) (memv (car p) run)) pages)) (ch #f) (sv #f) (ref #f) (acc '()))
            (match ps
              (() (reverse acc))
              (((leaf _ . page) . rest)
               (let line-loop ((ls (page-lines page)) (ch ch) (sv sv) (ref ref) (acc acc))
                 (match ls
                   (() (loop rest ch sv ref acc))
                   (((n . text) . more)
                    (let item-loop ((items (line-items text)) (ch ch) (sv sv) (ref ref) (acc acc))
                      (match items
                        (() (line-loop more ch sv ref acc))
                        ((('chapter c) . is) (item-loop is c sv ref acc))
                        ((('verse v . _) . is) (item-loop is ch v (and ch (list ch v "")) acc))
                        ((('common c v part) . is) (item-loop is ch sv (list c v part) acc))
                        (((? string? s) . is)
                         (item-loop is ch sv ref
                                    (if (and ref (string-any char-alphabetic? s))
                                        (match ref
                                          ((c v part)
                                           (cons (list c (if (string-null? part) v (string-append (number->string v) part))
                                                       (list (format #f "~a:~a" ch sv) leaf n))
                                                 acc)))
                                        acc)))
                        ((_ . is) (item-loop is ch sv ref acc)))))))))))
         (table (make-hash-table)))
    (for-each (match-lambda
                ((c v (swete leaf n))
                 (let* ((key (format #f "~a.~a" c v))
                        (old (hash-ref table key)))
                   (hash-set! table key (if old
                                            (append (take old 3) (list leaf n))
                                            (list swete leaf n leaf n))))))
              (english-numbering hits (versification-ranges book)))
    table))

;;; ---------------------------------------------------------------------------
;;; Translation files
;;; ---------------------------------------------------------------------------

;; A translated verse, ready to insert.
(define (translation-rows book-id chapter form words glosses)
  "Alist: ref status literal readable segments words untranslated notes uses,
for one (verse N ...) FORM of BOOK-ID's CHAPTER. USES is a hash word n ->
(lemma sense default?) of the literal layer's own words."
  (let* ((ref (format #f "~a.~a.~a" book-id chapter (cadr form)))
         (uses (make-hash-table))
         (checked (for-each (match-lambda
                        ((n lemma sense default? . _)
                         (unless (hash-ref uses n) (hash-set! uses n (list lemma sense default?)))))
                      (verse-uses form words glosses)))
         (readable (or (verse-field form 'readable) '("")))
         (aligned? (not (string? (car readable))))
         (literal (literal-clauses (or (verse-field form 'literal) '())))
         (segments '()) (aligned '()) (seg 0))
    (define (add-segment! layer clause s)
      (set! seg (+ seg 1))
      (set! segments (cons (list ref layer seg clause (text (segment-text s)) (if (null? (segment-refs s)) 1 0)) segments))
      (let loop ((refs (segment-refs s)) (pos 1))
        (match refs
          (() #t)
          ((r . more)
           (let* ((n (ref-n r)) (cont? (cont-ref? r))
                  (use (and (string=? layer "literal") (not cont?) (hash-ref uses n))))
             (set! aligned (cons (list ref layer seg pos n (if cont? 1 0)
                                       (and use (first use)) (and use (second use))
                                       (and (string=? layer "literal") (not cont?) (if (and use (third use)) 1 0)))
                                 aligned))
             (loop more (+ pos 1)))))))
    (for-each (match-lambda ((clause . segs) (for-each (lambda (s) (add-segment! "literal" clause s)) segs))) literal)
    (set! seg 0)
    (when aligned? (for-each (lambda (s) (add-segment! "readable" #f s)) readable))
    `((ref . ,ref)
      (status . ,(symbol->string (car (verse-field form 'status))))
      (literal . ,(segments-text (append-map cdr literal)))
      (readable . ,(if aligned? (segments-text readable) (car readable)))
      (segments . ,(reverse segments))
      (aligned . ,(reverse aligned))
      (untranslated . ,(append-map (lambda (items) (map (match-lambda ((n reason . _) (list ref n reason))) items))
                                   (verse-fields form 'untranslated)))
      (notes . ,(map (match-lambda
                       (((? string? s)) (list book-id chapter ref #f s))
                       ((n s) (list book-id chapter ref n s)))
                     (verse-fields form 'note)))
      (uses . ,uses))))

(define (generated-chapters book)
  "Chapter numbers with a generated literal layer in gsb/literal/NN-<id>/."
  (filter-map (lambda (p) (chapter-file-number (basename p)))
              (literal-files (book-file-stem book) ".scm")))

(define (merge-verse generated hand)
  "Rule 16a: the generated verse's status and literal layer, the hand verse's
readable layer and notes (word notes keep pointing at the Greek's numbers)."
  (match generated
    (('verse n items ...)
     `(verse ,n
             ,@(filter (lambda (i) (and (pair? i) (memq (car i) '(status literal)))) items)
             ,@(if hand (filter (lambda (i) (and (pair? i) (memq (car i) '(readable note)))) (cddr hand)) '())))))

(define (book-translation book greek glosses)
  "(verse-rows . other-notes) for BOOK: VERSE-ROWS as translation-rows makes
them (plus source 'generated or 'hand), OTHER-NOTES the book and chapter
notes as notes rows. A chapter generated in gsb/literal/ takes its literal
layer from there and its readable layer and notes from gsb/translation/."
  (let* ((id (book-field book 'id))
         (dir (translation-dir book))
         (book-notes (if (file-exists? (string-append dir "/book.scm"))
                         (filter-map (match-lambda (('note s) (list id #f #f #f s)) (_ #f))
                                     (read-forms (string-append dir "/book.scm")))
                         '()))
         (hand-chapters (filter-map chapter-file-number (chapter-files book)))
         (gen-chapters (generated-chapters book))
         (verses '()) (notes '()))
    (for-each
     (lambda (chapter)
       (let* ((hand-path (format #f "~a/~3,'0d.scm" dir chapter))
              (hand (if (file-exists? hand-path) (read-forms hand-path) '()))
              (gen (if (memv chapter gen-chapters) (read-forms (literal-chapter-path book chapter)) #f))
              (hand-verse (lambda (n) (find (lambda (f) (and (pair? f) (eq? (car f) 'verse) (equal? (cadr f) n))) hand))))
         (for-each (match-lambda (('note s) (set! notes (cons (list id chapter #f #f s) notes))) (_ #f)) hand)
         (for-each (match-lambda
                     ((and form ('verse n . _))
                      (let* ((words (hash-ref greek (format #f "~a.~a.~a" id chapter n) '()))
                             (merged (if gen (merge-verse form (hand-verse n)) form)))
                        (set! verses (cons (acons 'source (if gen "generated" "hand")
                                                  (translation-rows id chapter merged words glosses))
                                           verses))))
                     (_ #f))
                   (or gen hand))))
     (sort (lset-union = hand-chapters gen-chapters) <))
    (cons (reverse verses) (append book-notes (reverse notes)))))

;;; ---------------------------------------------------------------------------
;;; Building
;;; ---------------------------------------------------------------------------

(define %cc0
  "To the extent possible under law, the authors have dedicated all copyright and related rights in the Greek Source Bible (the translation, the transcription, the notes and all of its data) to the public domain worldwide under CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/). No permission or attribution is needed.")

(define (write-sql port)
  "Write the whole database as SQL to PORT, from the files under gsb/."
  (define (say fmt . args) (apply format (current-error-port) fmt args))
  (let* ((gloss-forms (read-gloss-forms))
         (checked (let ((errors (check-glosses gloss-forms)))
              (unless (null? errors)
                (for-each (lambda (e) (say "gsb/lexicon/glosses/: ~a~%" e)) errors)
                (error "fix the concordance first (see `make gsb/lint`)"))))
         (glosses (parse-glosses gloss-forms))
         ;; The scripted literal layer's data: its readings give LXX words their
         ;; grammar tag (words.morph).
         (literal-env (call-with-values load-literal-env
                        (lambda (env problems)
                          (unless (null? problems)
                            (for-each (lambda (p) (say "~a~%" p)) problems)
                            (error "fix gsb/literal/ first (see `make gsb/literal/check`)"))
                          env)))
         (books (read-books))
         (leaves (swete-leaves))
         (pages (map (lambda (b) (cons (book-field b 'id) (book-pages (book-field b 'id)))) books))
         (runs (map (lambda (b)
                      (let ((l (assoc (book-field b 'id) leaves)))
                        (cons (book-field b 'id)
                              (if l
                                  (leading-run (assoc-ref pages (book-field b 'id)) (string->number (fourth l))
                                               (or (string->number (sixth l)) 1))
                                  '()))))
                    books))
         (verse-id 0)
         (all-notes '()))
    (display (slurp "gsb/schema.sql") port)
    (display "BEGIN;\n" port)

    ;; meta and sources
    (let ((dates (append-map (lambda (p) (filter-map (match-lambda ((_ _ . page) (and=> (page-header page "done") car))) (cdr p))) pages)))
      (insert port "meta" '("key" "value")
              (map (lambda (r) (list (car r) (text (cadr r))))
              `(("name" "Greek Source Bible")
                ("short_name" "GSB")
                ("description" "The Greek Source Bible: an English translation of the whole Bible from Greek (the Old Testament from the Septuagint in our own transcription of Swete's edition, the New Testament from Nestle 1904 with the longer Textus Receptus readings restored and marked), with every Greek word tagged and every translation and transcription decision recorded.")
                ("homepage" "https://ursinia.net/bible/versions/gsb/")
                ("license" "CC0-1.0")
                ("license_statement" ,%cc0)
                ("updated" ,(if (null? dates) "" (last (sort dates string<?))))
                ("schema" ,(slurp "gsb/schema.sql"))
                ("resource_gaps" ,(markdown-section (slurp "gsb/README.md") "Known gaps in open resources"))
                ("readme_greek" ,(slurp "gsb/README.md"))
                ("readme_translation" ,(slurp "gsb/translation/README.md"))))))
    (insert port "sources" '("name" "readme")
            (filter-map (lambda (d) (let ((p (string-append "gsb/sources/" d "/README.md")))
                                      (and (file-exists? p) (list d (slurp p)))))
                        (dir-files "gsb/sources" "^[a-z0-9]+$")))

    ;; books
    (insert port "books" '("ord" "nn" "id" "english" "greek" "testament" "deuterocanonical" "role" "source" "notes" "chapters" "slug")
            (map (lambda (b i)
                   (append (list i)
                           (map (lambda (k) (book-field b k)) '(nn id english greek testament))
                           (list (if (string=? (book-field b 'deuterocanonical) "yes") 1 0))
                           (map (lambda (k) (book-field b k)) '(role source notes))
                           (list (string->number (book-field b 'chapters)) (book-anchor (book-field b 'id)))))
                 books (iota (length books) 1)))

    ;; verses, words, translation, search: one book at a time
    (for-each
     (lambda (book)
       (let* ((id (book-field book 'id))
              (path (greek-table-path book))
              (verses (if (file-exists? path) (read-greek-table path) '()))
              (greek (let ((h (make-hash-table))) (for-each (lambda (v) (hash-set! h (car v) (cdr v))) verses) h))
              (printed (let ((h (make-hash-table)))
                         (for-each (match-lambda ((c v text . _) (hash-set! h (string-append c "." v) text)) (_ #f))
                                   (tsv-rows (string-append %swete "/" (book-file-stem book) ".tsv")))
                         h))
              (where (verse-locations id (assoc-ref pages id) (assoc-ref runs id)))
              (tr (book-translation book greek glosses))
              (translated (let ((h (make-hash-table))) (for-each (lambda (t) (hash-set! h (assq-ref t 'ref) t)) (car tr)) h))
              (start verse-id))
         (set! all-notes (append all-notes (cdr tr)))
         (let ((rows
                (map (lambda (v)
                       (let* ((ref (car v))
                              (cv (string-join (cdr (string-split ref #\.)) "."))
                              (parts (string-split ref #\.))
                              (loc (hash-ref where cv '(#f #f #f #f #f))))
                         (set! verse-id (+ verse-id 1))
                         (append (list verse-id ref id (string->number (second parts)) (third parts))
                                 loc
                                 (list (hash-ref printed cv)
                                       (string-join (map (lambda (w) (string-append (word-pre* w) (word-text* w) (word-post* w))) (cdr v)) " ")))))
                     verses)))
           (insert port "verses" '("id" "ref" "book" "chapter" "verse" "swete_ref" "leaf_first" "line_first" "leaf_last" "line_last" "printed" "greek") rows))
         (insert port "words" '("ref" "n" "book" "pre" "word" "post" "lemma" "strong" "morph" "flags")
                 (append-map (lambda (v)
                               ;; LXX: lemma and tag of the reading the literal layer
                               ;; chooses, where it has a tag.
                               (let ((readings (if (equal? (book-field book 'testament) "OT")
                                                   (choose-readings literal-env (car v) (cdr v))
                                                   (map (const #f) (cdr v)))))
                                 (map (lambda (w r)
                                        (let ((tagged (and r (second r) (string-null? (word-morph* w)))))
                                          (list (car v) (word-n w) id (word-pre* w) (word-text* w) (word-post* w)
                                                (if tagged (first r) (word-lemma* w)) (word-strong* w)
                                                (if tagged (second r) (word-morph* w))
                                                (and (pair? (word-flags* w)) (json (list->vector (word-flags* w)))))))
                                      (cdr v) readings)))
                             verses))
         (for-each
          (lambda (t)
            (unless (hash-ref greek (assq-ref t 'ref))
              (error "translated verse has no Greek row in gsb/greek (run make gsb/lint)" (assq-ref t 'ref))))
          (car tr))
         (insert port "translation" '("ref" "layer" "status" "text" "source")
                 (append-map (lambda (t)
                               (cons (list (assq-ref t 'ref) "literal" (assq-ref t 'status) (text (assq-ref t 'literal)) (assq-ref t 'source))
                                     (if (string-null? (assq-ref t 'readable))
                                         '()
                                         (list (list (assq-ref t 'ref) "readable" (assq-ref t 'status) (assq-ref t 'readable) "hand")))))
                             (car tr)))
         (insert port "translation_segments" '("ref" "layer" "seg" "clause" "text" "supplied")
                 (append-map (lambda (t) (assq-ref t 'segments)) (car tr)))
         (insert port "translation_words" '("ref" "layer" "seg" "pos" "n" "cont" "lemma" "sense" "default_sense")
                 (append-map (lambda (t) (assq-ref t 'aligned)) (car tr)))
         (insert port "untranslated" '("ref" "n" "reason")
                 (append-map (lambda (t) (assq-ref t 'untranslated)) (car tr)))
         (set! all-notes (append all-notes (append-map (lambda (t) (assq-ref t 'notes)) (car tr))))
         (insert port "search" '("rowid" "greek" "greek_plain" "lemmas" "english")
                 (map (lambda (v id)
                        (let* ((t (hash-ref translated (car v)))
                               (uses (and t (assq-ref t 'uses))))
                          (list id
                                (string-join (map word-text* (cdr v)) " ")
                                (string-join (map (lambda (w) (fold-key (word-text* w))) (cdr v)) " ")
                                (string-join (filter-map (lambda (w)
                                                           (let ((l (or (and uses (and=> (hash-ref uses (word-n w)) first))
                                                                        (word-lemma* w))))
                                                             (and l (not (string-null? l)) l)))
                                                         (cdr v))
                                             " ")
                                (if t (string-append (assq-ref t 'literal) " " (assq-ref t 'readable)) ""))))
                      verses (iota (length verses) (+ start 1))))))
     books)

    ;; notes (book, chapter, verse and word notes, in file order per book)
    (insert port "notes" '("id" "book" "chapter" "ref" "n" "markdown")
            (map cons (iota (length all-notes) 1) all-notes))

    ;; concordance and avoid list
    (insert port "glosses" '("lemma" "sense" "ord" "gloss" "forms" "readable" "why")
            (append-map (match-lambda
                          (('lemma lemma senses ...)
                           (map (lambda (s i)
                                  (let ((gloss (cdr (assq 'gloss (cddr s))))
                                        (readable (assq 'readable (cddr s))))
                                    (list (string-normalize-nfc lemma) (symbol->string (cadr s)) i
                                          ;; '' is a gloss (unrendered), not NULL: written as ''''.
                                          (text (car gloss))
                                          (json (list->vector gloss))
                                          (and readable (cadr readable))
                                          (cadr (assq 'why (cddr s))))))
                                senses (iota (length senses) 1))))
                        gloss-forms))
    (insert port "readable_avoid" '("word" "use" "why")
            (if (file-exists? "gsb/lexicon/readable-avoid.scm")
                (map (match-lambda ((word use why) (list word use why)))
                     (parse-avoid (read-forms "gsb/lexicon/readable-avoid.scm")))
                '()))
    (insert-tsv port "lexicon" '("strong" "lemma" "strongs_headword" "gloss" "definition" "definition_source")
                "gsb/lexicon/strongs.tsv")

    ;; transcription
    (insert port "transcription_pages" '("book" "leaf" "scan" "volume" "printed_page" "box" "done_date" "method" "status" "in_tables" "text")
            (append-map
             (match-lambda
               ((book . ps)
                (map (match-lambda
                       ((leaf volume . page)
                        (let ((scan (page-header page "scan"))
                              (done (page-header page "done"))
                              (path (format #f "~a/pages/~a/v~a-~4,'0d.txt" %swete book volume leaf)))
                          (list book leaf (if scan (first scan) "") volume (and scan (third scan))
                                (and=> (page-header page "box") (lambda (b) (string-join b " ")))
                                (and done (first done)) (and done (pair? (cdr done)) (second done))
                                (if done "done" "in progress")
                                (if (memv leaf (assoc-ref runs book)) 1 0)
                                (slurp path)))))
                     ps)))
             pages))
    (insert-tsv port "transcription_decisions" '("book" "scan" "leaf" "line" "reading_a" "reading_b" "reading_c" "chosen" "basis")
                (string-append %swete "/decisions.tsv"))
    (insert-tsv port "transcription_provenance" '("book" "chapter" "scan" "leaves" "printed_pages" "date" "method")
                (string-append %swete "/provenance.tsv"))
    (insert port "transcription_leaves" '("book" "volume" "scan" "first_leaf" "last_leaf" "step" "note") leaves)
    (insert-tsv port "versification" '("book" "hebrew_from" "hebrew_to" "english") (string-append %swete "/versification.tsv"))

    ;; reports
    (insert-tsv port "nt_variants" '("ref" "kind" "nestle1904" "tr") "gsb/reports/nt-variants.tsv")
    (insert-tsv port "lxx_coverage" '("book" "status" "tokens" "with_lemma" "lemma_pct" "with_strong" "strong_pct" "types" "types_with_lemma" "type_pct")
                "gsb/reports/lxx-coverage.tsv")
    (insert-tsv port "lxx_unmatched_forms" '("rank" "form" "count") "gsb/reports/lxx-unmatched-forms.tsv")
    (insert-tsv port "lxx_capitals" '("ref" "n" "swete" "status" "restored") "gsb/reports/lxx-capitals.tsv")
    (insert-tsv port "nt_unaccented" '("ref" "n" "word" "strong") "gsb/reports/nt-unaccented.tsv")

    ;; The scripted literal layer's data (gsb/literal/README.md).
    (call-with-values literal-form-rows
      (lambda (rows _)
        (insert port "form_analyses" '("form" "ord" "lemma" "tag" "sense" "note" "file")
                (map (lambda (r i) (match r ((path form lemma tag sense note) (list form i lemma tag sense note path))))
                     rows (iota (length rows) 1)))))
    (call-with-values literal-override-forms
      (lambda (forms _)
        (insert port "literal_overrides" '("ord" "ref" "n" "kind" "lemma" "tag" "sense" "english" "before" "after" "subject" "why" "file")
                (map (lambda (f i)
                       (match f
                         ((path 'word at items ...)
                          (let* ((parts (string-split at #\#))
                                 (item (lambda (k) (let ((x (assq k items))) (and x (let ((v (cadr x))) (if (symbol? v) (symbol->string v) (if (equal? v "") 'empty v))))))))
                            (list i (car parts) (string->number (cadr parts)) "word"
                                  (item 'lemma) (item 'tag) (item 'sense) (item 'english) (item 'before) (item 'after) (item 'subject)
                                  (or (item 'why) 'empty) path)))
                         ((path 'verse ref items ...)
                          (list i ref #f "verse" #f #f #f #f #f #f #f (cadr (assq 'why items)) path))))
                     forms (iota (length forms) 1)))))
    (insert port "literal_phrases" '("ord" "lemmas" "senses" "english" "tag" "why")
            (map (lambda (p i)
                   (let ((f (lambda (k) (let ((x (assq k (cdr p)))) (and x (cdr x))))))
                     (list i (json (list->vector (f 'lemmas))) (json (list->vector (map symbol->string (f 'senses))))
                           (car (f 'english)) (and (f 'tag) (car (f 'tag))) (car (f 'why)))))
                 (literal-phrase-forms) (iota (length (literal-phrase-forms)) 1)))
    ;; ponytail: write-sql is one long function; split it into a list of steps
    ;; once it gains more inputs.

    (display "INSERT INTO search(search) VALUES('optimize');\nCOMMIT;\nVACUUM;\n" port)))

(define (build-database! out)
  "Build the database file OUT from gsb/ (replacing it). Raises on failure."
  (let ((tmp (string-append out ".tmp")))
    (when (file-exists? tmp) (delete-file tmp))
    (let mk ((d (dirname out)))
      (unless (file-exists? d) (mk (dirname d)) (mkdir d)))
    (let ((port (open-pipe* OPEN_WRITE "sqlite3" "-bail" tmp)))
      (set-port-encoding! port "UTF-8")
      (write-sql port)
      (unless (zero? (or (status:exit-val (close-pipe port)) 1))
        (error "sqlite3 failed while building" out)))
    (rename-file tmp out)))
