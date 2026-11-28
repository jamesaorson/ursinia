;; Copyright (C) 2026
;;
;; Greek Source Bible translation files: reading them and checking them against
;; the Greek tables and the concordance. The format is documented in
;; gsb/translation/README.md. Shared by scripts/gsb-check.scm (the checker) and
;; scripts/gsb-site.scm (the site generator); the checks themselves take plain
;; data so scripts/lib/test/gsb-translation/test.scm can run them directly.

(define-module (scripts lib gsb-translation)
  #:use-module (scripts lib gsb)
  #:use-module (ice-9 format)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (read-books
            book-field
            book-file-stem
            greek-table-path
            read-greek-table
            word-n word-pre* word-text* word-post* word-lemma* word-strong* word-morph* word-flags*
            read-forms
            gloss-files
            read-gloss-forms
            parse-glosses
            check-glosses
            check-gloss-files
            translation-dir
            chapter-files
            chapter-file-number
            check-chapter
            check-avoid
            parse-avoid
            segment-text segment-refs ref-n ref-sense ref-lemma cont-ref?
            literal-clauses literal-segments
            verse-field verse-fields verse-uses default-sense
            segments-text strip-supplied))

;;; ---------------------------------------------------------------------------
;;; Books and Greek tables
;;; ---------------------------------------------------------------------------

(define %book-columns '(nn id english greek testament deuterocanonical role source notes chapters))

(define (read-books)
  "Rows of gsb/books.tsv as alists keyed by column name."
  (map (lambda (line) (map cons %book-columns (split-tab line)))
       (cdr (read-lines "gsb/books.tsv"))))

(define (book-field book field) (or (assq-ref book field) ""))

(define (book-file-stem book)
  (string-append (book-field book 'nn) "-" (book-field book 'id)))

(define (greek-table-path book)
  (string-append "gsb/greek/" (book-file-stem book) ".tsv"))

;; A word row: (n pre word post lemma strong morph flags), N an integer and
;; FLAGS a list of strings.
(define word-n first)
(define word-pre* second)
(define word-text* third)
(define word-post* fourth)
(define word-lemma* fifth)
(define word-strong* sixth)
(define word-morph* seventh)
(define (word-flags* w) (list-ref w 7))

(define (read-greek-table path)
  "Verses of a gsb/greek table in order: a list of (ref . word rows)."
  (let loop ((lines (cdr (read-lines path))) (ref #f) (words '()) (acc '()))
    (define (flush) (if ref (cons (cons ref (reverse words)) acc) acc))
    (match lines
      (() (reverse (flush)))
      ((line . rest)
       (match (split-tab line)
         ((r n pre word post lemma strong morph . flags)
          (let ((row (list (string->number n) pre word post lemma strong morph
                           (if (or (null? flags) (string-null? (car flags)))
                               '()
                               (string-split (car flags) #\,)))))
            (if (equal? r ref)
                (loop rest ref (cons row words) acc)
                (loop rest r (list row) (flush)))))
         (_ (error "malformed row in" path line)))))))

;;; ---------------------------------------------------------------------------
;;; Reading Scheme data files
;;; ---------------------------------------------------------------------------

(define (read-forms path)
  "Every top-level form in PATH, in order."
  (call-with-input-file path
    (lambda (port)
      (let loop ((acc '()))
        (let ((form (read port)))
          (if (eof-object? form) (reverse acc) (loop (cons form acc))))))))

;;; ---------------------------------------------------------------------------
;;; Concordance: gsb/lexicon/glosses.scm
;;;
;;; (lemma "λόγος" (sense word (gloss "word" "words") (why "...")) ...)
;;; A sense may add (readable "word"): the readable layer's word where it
;;; differs from the literal gloss (shown in the concordance, not checked).
;;; Parsed into a hash: lemma -> list of (sense-name glosses why); the first
;;; sense is the lemma's default, what a bare word number means.
;;; ---------------------------------------------------------------------------

(define (sense-field sense key)
  (let ((f (find (lambda (x) (and (pair? x) (eq? (car x) key))) (cddr sense))))
    (and f (cdr f))))

(define %glosses-dir "gsb/lexicon/glosses")

(define (gloss-files)
  "The concordance files: gsb/lexicon/glosses/*.scm in name order (one per
initial letter), or the older single gsb/lexicon/glosses.scm."
  (if (file-exists? %glosses-dir)
      (map (lambda (f) (string-append %glosses-dir "/" f))
           (sort (filter (lambda (f) (string-suffix? ".scm" f))
                         (let ((d (opendir %glosses-dir)))
                           (let loop ((acc '()))
                             (let ((e (readdir d)))
                               (if (eof-object? e) (begin (closedir d) acc) (loop (cons e acc)))))))
                 string<?))
      (if (file-exists? "gsb/lexicon/glosses.scm") (list "gsb/lexicon/glosses.scm") '())))

(define (read-gloss-forms)
  "Every (lemma ...) form of the concordance, file by file."
  (append-map read-forms (gloss-files)))

(define (check-gloss-files files)
  "check-glosses over FILES, a list of (path . forms), naming the files of a
lemma listed twice."
  (check-glosses (append-map cdr files)
                 (append-map (match-lambda ((path . forms) (map (const path) forms))) files)))

(define* (check-glosses forms #:optional paths)
  "Problems with the concordance forms, as strings (empty when it is valid).
PATHS, when given, is each form's file, for naming a duplicate's files."
  (let ((seen (make-hash-table)))
    (append-map
     (lambda (form path)
       (match form
         (('lemma (? string? lemma) senses ...)
          (let* ((key (string-normalize-nfc lemma)) (dup (hash-ref seen key)))
            (unless dup (hash-set! seen key (or path #t)))
            (append
             (cond ((not dup) '())
                   (path (list (format #f "lemma ~a is listed twice: ~a and ~a; merge its senses into the first entry" lemma dup path)))
                   (else (list (format #f "lemma ~a is listed twice; merge its senses into the first entry" lemma))))
             (if (null? senses) (list (format #f "lemma ~a has no senses; add (sense <name> (gloss \"...\") (why \"...\"))" lemma)) '())
             (let ((names (filter-map (lambda (s) (and (pair? s) (pair? (cdr s)) (cadr s))) senses)))
               (if (= (length names) (length (delete-duplicates names)))
                   '()
                   (list (format #f "lemma ~a: two senses share a name; sense names must be unique per lemma" lemma))))
             (append-map
              (lambda (s)
                (match s
                  (('sense (? symbol? name) . _)
                   (let ((gloss (sense-field s 'gloss))
                         (why (sense-field s 'why))
                         (readable (sense-field s 'readable)))
                     (append
                      (if (or (not readable) (and (= 1 (length readable)) (string? (car readable))
                                                  (not (string-null? (string-trim-both (car readable))))))
                          '()
                          (list (format #f "lemma ~a sense ~a: (readable ...) takes one string, the readable layer's word: (readable \"moving\")" lemma name)))
                      (if (and gloss (pair? gloss) (every string? gloss)) '()
                          (list (format #f "lemma ~a sense ~a: needs (gloss \"english\" \"other form\" ...); use (gloss \"\") for a word English leaves unrendered" lemma name)))
                      (if (and why (pair? why) (string? (car why)) (not (string-null? (string-trim-both (car why))))) '()
                          (list (format #f "lemma ~a sense ~a: needs (why \"the reasoning for this gloss\")" lemma name))))))
                  (_ (list (format #f "lemma ~a: expected (sense <name> (gloss ...) (why ...)), got ~s" lemma s)))))
              senses))))
         (_ (list (format #f "expected (lemma \"<greek>\" (sense ...) ...), got ~s" form)))))
     forms (or paths (map (const #f) forms)))))

(define (parse-glosses forms)
  "Hash of lemma -> list of (name glosses why) from already-checked FORMS."
  (let ((table (make-hash-table)))
    (for-each (match-lambda
                (('lemma lemma senses ...)
                 (hash-set! table (string-normalize-nfc lemma)
                            (map (lambda (s) (list (cadr s) (sense-field s 'gloss) (car (sense-field s 'why))))
                                 senses))))
              forms)
    table))

;;; ---------------------------------------------------------------------------
;;; Translation files: gsb/translation/NN-<id>/CCC.scm
;;; ---------------------------------------------------------------------------

(define (translation-dir book) (string-append "gsb/translation/" (book-file-stem book)))

(define (chapter-file-number name)
  "The chapter number of a chapter file name like 001.scm, or #f."
  (and (= (string-length name) 7)
       (string-suffix? ".scm" name)
       (string-every char-numeric? (substring name 0 3))
       (string->number (substring name 0 3))))

(define (chapter-files book)
  "Sorted chapter file names in BOOK's translation directory (none if absent)."
  (let ((dir (translation-dir book)))
    (if (file-exists? dir)
        (sort (filter (lambda (f) (string-suffix? ".scm" f))
                      (let ((d (opendir dir)))
                        (let loop ((acc '()))
                          (let ((e (readdir d)))
                            (if (eof-object? e) (begin (closedir d) acc) (loop (cons e acc)))))))
              string<?)
        '())))

;; Segments: ("english text" ref ...). A ref is N, (N sense), (N sense "lemma"),
;; or (cont N): the segment continues Greek word N, whose own ref sits in an
;; earlier segment ("sent" 2) ("him" 3) ("out" (cont 2)).
(define segment-text car)
(define segment-refs cdr)
(define (cont-ref? r) (and (pair? r) (eq? (car r) 'cont)))
(define (ref-n r)
  (cond ((cont-ref? r) (and (pair? (cdr r)) (cadr r)))
        ((pair? r) (car r))
        (else r)))
(define (ref-sense r) (and (pair? r) (not (cont-ref? r)) (pair? (cdr r)) (cadr r)))
(define (ref-lemma r) (and (pair? r) (not (cont-ref? r)) (pair? (cdr r)) (pair? (cddr r)) (caddr r)))

(define (verse-fields verse key)
  "Every (KEY ...) item of a (verse N item ...) form, without the key."
  (filter-map (lambda (x) (and (pair? x) (eq? (car x) key) (cdr x))) (cddr verse)))

(define (verse-field verse key)
  (let ((all (verse-fields verse key))) (and (pair? all) (car all))))

(define (literal-clauses items)
  "The literal layer as a list of (clause-index-or-#f . segments)."
  (let loop ((items items) (i 0) (acc '()))
    (match items
      (() (reverse acc))
      ((('clause segs ...) . rest) (loop rest (+ i 1) (cons (cons i segs) acc)))
      ((seg . rest) (loop rest i (cons (list #f seg) acc))))))

(define (literal-segments items)
  "The literal layer's segments in order, clauses flattened."
  (append-map cdr (literal-clauses items)))

(define (segment? s) (and (list? s) (pair? s) (string? (car s))))

(define (segments-text segs)
  (string-join (map segment-text segs) " "))

(define (words-of text)
  "Lowercased English words of TEXT, padded with spaces for whole-word search;
a possessive \"'s\" is dropped (\"Lot's\" holds the gloss \"Lot\")."
  (string-append
   " "
   (string-join (map (lambda (t) (if (string-suffix? "'s" t) (substring t 0 (- (string-length t) 2)) t))
                     (string-tokenize (string-downcase text)
                                      (char-set-union char-set:letter (char-set #\' #\-))))
                " ")
   " "))

(define (has-word? text w) (string-contains (words-of text) (words-of w)))
(define (has-any-word? text ws) (any (lambda (w) (has-word? text w)) ws))

(define (strip-supplied text)
  "TEXT without its [supplied] parts."
  (let loop ((cs (string->list text)) (in? #f) (acc '()))
    (match cs
      (() (list->string (reverse acc)))
      ((#\[ . rest) (loop rest #t acc))
      ((#\] . rest) (loop rest #f acc))
      ((c . rest) (loop rest in? (if in? acc (cons c acc)))))))

(define (brackets-ok? text)
  "Each [ is closed by a ] before the next [, and no ] is stray."
  (let loop ((cs (string->list text)) (in? #f))
    (match cs
      (() (not in?))
      ((#\[ . rest) (and (not in?) (loop rest #t)))
      ((#\] . rest) (and in? (loop rest #f)))
      ((_ . rest) (loop rest in?)))))

(define (supplied-only? text)
  "Whether every word of TEXT is [supplied]; punctuation may stand outside."
  (not (string-any char-alphabetic? (strip-supplied text))))

(define (primary-refs segs)
  "Hash of word number -> the first ref in SEGS that aligns it (not a (cont N))."
  (let ((h (make-hash-table)))
    (for-each (lambda (s)
                (when (segment? s)
                  (for-each (lambda (r)
                              (let ((n (ref-n r)))
                                (when (and (integer? n) (not (cont-ref? r)) (not (hash-ref h n)))
                                  (hash-set! h n r))))
                            (segment-refs s))))
              segs)
    h))

(define (word-lemma-resolver words segs)
  "Word number -> its lemma (NFC): the lemma written in the word's literal ref
when there is one, else the table's; #f for a word the verse does not have."
  (let ((prim (primary-refs segs)))
    (lambda (n)
      (let ((w (and (integer? n) (find (lambda (w) (eqv? (word-n w) n)) words)))
            (r (hash-ref prim n)))
        (and w (string-normalize-nfc (or (and r (ref-lemma r)) (word-lemma* w))))))))

(define (default-sense glosses lemma)
  "The first sense listed for LEMMA in the concordance: what a bare ref means."
  (let ((senses (and lemma (hash-ref glosses lemma))))
    (and (pair? senses) (caar senses))))

(define (verse-uses form words glosses)
  "Each Greek word aligned in a verse's literal layer, in English order, as
(n lemma sense default? english): DEFAULT? is #t for a bare ref (the lemma's
first sense), ENGLISH the word's segment joined to its (cont n) segments by
\" … \"."
  (let* ((segs (filter segment? (literal-segments (or (verse-field form 'literal) '()))))
         (lemma-of (word-lemma-resolver words segs)))
    (append-map
     (lambda (s)
       (filter-map
        (lambda (r)
          (let* ((n (ref-n r))
                 (lemma (and (integer? n) (not (cont-ref? r))
                             (if (ref-lemma r) (string-normalize-nfc (ref-lemma r)) (lemma-of n)))))
            (and lemma
                 (list n lemma (or (ref-sense r) (default-sense glosses lemma)) (not (ref-sense r))
                       (string-join
                        (cons (segment-text s)
                              (filter-map (lambda (s2)
                                            (and (any (lambda (r2) (and (cont-ref? r2) (eqv? (ref-n r2) n))) (segment-refs s2))
                                                 (segment-text s2)))
                                          segs))
                        " … ")))))
        (segment-refs s)))
     segs)))

;;; ---------------------------------------------------------------------------
;;; Keeping the source's ambiguity (gsb/AGENTS.md, rule 9)
;;; ---------------------------------------------------------------------------

(define %demonstratives '("οὗτος" "ἐκεῖνος" "ὅδε"))
(define %pointing '("this" "that" "these" "those"))
(define %personal '("he" "him" "his" "himself" "she" "her" "hers" "herself"
                    "it" "its" "itself" "they" "them" "their" "theirs" "themselves"))

(define (name-table glosses)
  "Alist of proper name -> the lemmas that may stand behind it: every
capitalized gloss of a sense named `name`, plus \"God\" and \"Lord\"."
  (let ((pairs (hash-fold
                (lambda (lemma senses acc)
                  (append (append-map
                           (match-lambda
                             ((name gs . _)
                              (filter-map (lambda (g)
                                            (and (or (member g '("God" "Lord"))
                                                     (and (eq? name 'name) (not (string-null? g))
                                                          (char-upper-case? (string-ref g 0))))
                                                 (cons g lemma)))
                                          gs)))
                           senses)
                          acc))
                '() glosses)))
    (map (lambda (g) (cons g (sort (map cdr (filter (lambda (p) (string=? (car p) g)) pairs)) string<?)))
         (sort (delete-duplicates (map car pairs)) string<?))))

(define (count-name text name)
  "How often NAME occurs in TEXT as a whole word, case-sensitive."
  (count (lambda (t) (string=? t name)) (string-tokenize text char-set:letter)))

;;; ---------------------------------------------------------------------------
;;; Words the readable layer avoids: gsb/lexicon/readable-avoid.scm
;;;
;;; (avoid "borne" (use "moving") (why "..."))
;;; ---------------------------------------------------------------------------

(define (avoid-field items key)
  (let ((x (find (lambda (i) (and (pair? i) (eq? (car i) key) (pair? (cdr i)))) items)))
    (and x (cadr x))))

(define (check-avoid forms)
  "Problems with the readable-avoid forms, as strings (empty when valid)."
  (filter-map
   (match-lambda
     (('avoid (? string? w) items ...)
      (let ((use (avoid-field items 'use)) (why (avoid-field items 'why)))
        (and (not (and (string? use) (string? why) (not (string-null? (string-trim-both why)))
                       (not (string-null? (string-trim-both w)))))
             (format #f "avoid ~s: needs a word, (use \"replacement\") and (why \"reason\")" w))))
     (x (format #f "expected (avoid \"word\" (use \"replacement\") (why \"reason\")), got ~s" x)))
   forms))

(define (parse-avoid forms)
  "List of (word use why) from already-checked FORMS."
  (map (match-lambda (('avoid w items ...) (list w (avoid-field items 'use) (avoid-field items 'why))))
       forms))

;;; ---------------------------------------------------------------------------
;;; The chapter checker
;;; ---------------------------------------------------------------------------

(define* (check-chapter file book-id chapter forms verses glosses #:key (avoid '()) (warn (const #f)))
  "Problems in one chapter file, as strings naming FILE and the verse. FORMS is
the file's top-level forms, VERSES the book's Greek table (see
read-greek-table), GLOSSES the parsed concordance, AVOID the parsed
readable-avoid list. WARN is called with each warning (same form, does not
fail the check)."
  (let ((table (make-hash-table))
        (seen (make-hash-table))
        (names (name-table glosses)))
    (for-each (lambda (v) (hash-set! table (car v) (cdr v))) verses)
    (define (err where fmt . args)
      (string-append file ": " where ": " (apply format #f fmt args)))
    (define (check-verse form)
      (let* ((num (cadr form))
             (ref (format #f "~a.~a.~a" book-id chapter num))
             (words (hash-ref table ref))
             (e (lambda (fmt . args) (apply err ref fmt args))))
        (cond
         ((not words)
          (list (e "no such verse in the Greek table gsb/greek/; check the verse number (lettered verses are strings: (verse \"35a\" ...))")))
         ((hash-ref seen ref)
          (list (e "verse appears twice; merge the two (verse ...) forms")))
         (else
          (hash-set! seen ref #t)
          (let* ((word-at (lambda (n) (find (lambda (w) (eqv? (word-n w) n)) words)))
                 (status (verse-field form 'status))
                 (literal (verse-field form 'literal))
                 (readable (verse-field form 'readable))
                 (untranslated (or (verse-field form 'untranslated) '()))
                 (used (make-hash-table))
                 (known '(status literal readable untranslated note))
                 (segs (if literal (literal-segments literal) '()))
                 (lemma-of (word-lemma-resolver words segs))
                 (cont-texts (make-hash-table)))
            (define (ref-lemma* r)
              (if (ref-lemma r) (string-normalize-nfc (ref-lemma r)) (lemma-of (ref-n r))))
            (define (greek n) (let ((w (word-at n))) (if w (word-text* w) "?")))
            (define (use! n what)
              (cond
               ((not (and (integer? n) (word-at n)))
                (list (e "~a refers to Greek word ~s, which this verse does not have (words 1-~a)" what n (length words))))
               ((hash-ref used n)
                (list (e "Greek word ~a (~a) is aligned twice; give each Greek word to exactly one segment (a later part of its English takes (cont ~a))" n (greek n) n)))
               (else (hash-set! used n #t) '())))
            ;; (cont N) must come after the segment that aligns N. Also fills
            ;; cont-texts (N -> the continuing segments' text), which
            ;; check-ref reads, so this runs first.
            (define (check-conts)
              (let ((first (make-hash-table)) (errs '()))
                (for-each
                 (lambda (s i)
                   (when (segment? s)
                     (for-each
                      (lambda (r)
                        (let ((n (ref-n r)) (text (segment-text s)))
                          (define (bad! m) (set! errs (cons m errs)))
                          (cond
                           ((not (cont-ref? r))
                            (when (and (integer? n) (not (hash-ref first n))) (hash-set! first n i)))
                           ((not (and (integer? n) (word-at n)))
                            (bad! (e "segment ~s continues Greek word ~s, which this verse does not have (words 1-~a)" text n (length words))))
                           ((not (hash-ref first n))
                            (bad! (e "segment ~s has (cont ~a), but no earlier segment aligns word ~a (~a); put ~a (with its sense) in the segment where its English starts and (cont ~a) in the later part"
                                     text n n (greek n) n n)))
                           ((= (hash-ref first n) i)
                            (bad! (e "segment ~s both aligns and continues word ~a; drop the (cont ~a)" text n n)))
                           (else
                            (hash-set! cont-texts n (append (hash-ref cont-texts n '()) (list text)))))))
                      (segment-refs s))))
                 segs (iota (length segs)))
                (reverse errs)))
            (define (check-ref seg r)
              (let* ((n (ref-n r))
                     (w (and (integer? n) (word-at n)))
                     (lemma (and w (string-normalize-nfc (or (ref-lemma r) (word-lemma* w)))))
                     (senses (and lemma (hash-ref glosses lemma)))
                     (conts (map strip-supplied (hash-ref cont-texts n '())))
                     (text (string-join (cons (strip-supplied (segment-text seg)) conts) " ")))
                (cond
                 ((not w) '())
                 ((string-null? lemma)
                  (list (e "Greek word ~a (~a) has no lemma in the table; write (~a <sense> \"<lemma>\")" n (word-text* w) n)))
                 ((not senses)
                  (list (e "lemma ~a (word ~a, ~a) is not in the concordance; add (lemma \"~a\" (sense <name> (gloss \"...\") (why \"...\")))"
                           lemma n (word-text* w) lemma)))
                 (else
                  (let ((sense (if (ref-sense r) (assq (ref-sense r) senses) (car senses))))
                    (cond
                     ((not sense)
                      (list (e "lemma ~a has no sense ~a (it has ~{~a~^, ~}); fix the name or add the sense to gsb/lexicon/glosses.scm"
                               lemma (ref-sense r) (map car senses))))
                     ((or (member "" (cadr sense))
                          (any (lambda (g) (string-contains (words-of text) (words-of g))) (cadr sense)))
                      '())
                     (else
                      (list (e "segment ~s~a renders ~a (word ~a) but holds none of its glosses for sense ~a~a (~{~s~^, ~}); use the concordance gloss, name another sense (~a <sense>), or add a form/sense in gsb/lexicon/glosses.scm"
                               (segment-text seg)
                               (if (null? conts) "" (format #f " with its (cont ~a) part~p ~s" n (length conts) (string-join conts " … ")))
                               lemma n (car sense) (if (ref-sense r) "" " (the default: first listed)") (cadr sense) n)))))))))
            (define (check-segment seg)
              (match seg
                (((? string? text) refs ...)
                 (let ((primaries (remove cont-ref? refs))
                       (lemmas (filter-map ref-lemma* refs))
                       (bare (strip-supplied text)))
                   (append
                    (cond
                     ((string-null? (string-trim-both text))
                      (list (e "empty segment; remove it")))
                     ((not (brackets-ok? text))
                      (list (e "segment ~s has unbalanced or nested brackets; write each supplied word or phrase as [word]" text)))
                     ((supplied-only? text)
                      (if (null? refs) '()
                          (list (e "segment ~s is all [supplied] but has Greek words; a supplied word has no Greek behind it, so drop the numbers or take the translated words out of the brackets" text))))
                     ((null? refs)
                      (list (e "segment ~s has no Greek words; add the word numbers it translates or bracket it as [supplied]" text)))
                     (else
                      (append
                       (if (and (has-word? bare "the") (not (member "ὁ" lemmas)))
                           (list (e "segment ~s has \"the\" but no Greek article behind it; bracket it: [the]" text))
                           '())
                       (if (and (has-any-word? bare '("a" "an"))
                                (not (any (lambda (l) (member l '("τις" "εἷς"))) lemmas)))
                           (list (e "segment ~s has an indefinite article Greek does not have; bracket it: [a]" text))
                           '()))))
                    (append-map (lambda (r) (use! (ref-n r) (format #f "segment ~s" text))) primaries)
                    (append-map (lambda (r) (check-ref seg r)) primaries))))
                (_ (list (e "malformed literal segment ~s; expected (\"english\" word-number ...)" seg)))))
            ;; Keep the source's ambiguity: per aligned segment.
            (define (ambiguity layer seg)
              (if (not (segment? seg))
                  '()
                  (let* ((text (segment-text seg))
                         (refs (segment-refs seg))
                         (lemmas (filter-map ref-lemma* refs))
                         (demos (filter (lambda (r) (and (not (cont-ref? r)) (member (ref-lemma* r) %demonstratives))) refs))
                         (seg-names (filter (lambda (p) (positive? (count-name text (car p)))) names)))
                    (append
                     ;; A demonstrative's English is its segment plus, in the
                     ;; literal layer, its (cont N) parts.
                     (filter-map
                      (lambda (r)
                        (let* ((n (ref-n r))
                               (all (string-join (cons text (if (equal? layer "literal") (hash-ref cont-texts n '()) '())) " ")))
                          (and (or (has-any-word? all %personal) (any (lambda (p) (positive? (count-name all (car p)))) names))
                               (not (has-any-word? all %pointing))
                               (e "~a segment ~s renders the demonstrative ~a (word ~a, ~a) as a personal pronoun or name; keep it a demonstrative (\"this [one]\", \"that [one]\") so the referent stays as open as in the Greek (gsb/AGENTS.md rule 9)"
                                  layer text (ref-lemma* r) n (greek n)))))
                      demos)
                     (filter-map
                      (match-lambda
                        ((name . name-lemmas)
                         (and (not (any (lambda (l) (member l name-lemmas)) lemmas))
                              (e "~a segment ~s says ~s, but its Greek (~a) has no ~{~a~^ or ~}; a name the Greek does not say resolves an open referent: keep the Greek's pronoun or demonstrative, or align the name to the word that says it (gsb/AGENTS.md rule 9)"
                                 layer text name
                                 (if (null? refs) "none: the segment is supplied"
                                     (string-join (map (lambda (r) (greek (ref-n r))) refs) " "))
                                 name-lemmas))))
                      seg-names)))))
            ;; A plain-string readable layer, against the literal layer.
            (define (readable-ambiguity text)
              (let ((lit (string-join (map segment-text (filter segment? segs)) " "))
                    (pointer (find (lambda (s)
                                     (and (segment? s)
                                          (has-any-word? (segment-text s) %pointing)
                                          (any (lambda (r) (member (ref-lemma* r) %demonstratives)) (segment-refs s))))
                                   segs)))
                (when (and pointer (not (has-any-word? text %pointing)))
                  (let ((r (find (lambda (r) (member (ref-lemma* r) %demonstratives)) (segment-refs pointer))))
                    (warn (e "warning: the literal layer points with ~s (~a, word ~a) but the readable layer has no this/that/these/those; check that it kept the demonstrative rather than a pronoun or name"
                             (segment-text pointer) (greek (ref-n r)) (ref-n r)))))
                (filter-map (match-lambda
                              ((name . _)
                               (let ((r (count-name text name)) (l (count-name lit name)))
                                 (and (> r l)
                                      (e "readable layer says ~s ~a time~:p, the literal layer ~a; a name the Greek does not say resolves an open referent: use the pronoun or demonstrative the Greek has (gsb/AGENTS.md rule 9)"
                                         name r l)))))
                            names)))
            (define (avoid-errors text)
              (filter-map (match-lambda
                            ((w use why)
                             (and (has-word? text w)
                                  (e "readable layer uses ~s; write ~s instead (~a; gsb/lexicon/readable-avoid.scm)" w use why))))
                          avoid))
            (let ((cont-errors (check-conts)))
              (append
               (filter-map (lambda (x)
                             (and (not (and (pair? x) (memq (car x) known)))
                                  (e "unknown item ~s; a verse holds only ~{(~a ...)~^ ~}" x known)))
                           (cddr form))
               (cond
                ((not status) (list (e "missing (status draft)")))
                ((not (and (= 1 (length status)) (memq (car status) '(draft reviewed))))
                 (list (e "status must be (status draft) or (status reviewed), got ~s" (cons 'status status))))
                (else '()))
               cont-errors
               (if literal
                   (append-map check-segment segs)
                   (list (e "missing (literal ...)")))
               (append-map (lambda (s) (ambiguity "literal" s)) segs)
               (append-map (match-lambda
                             (((? integer? n) (? string? why))
                              (append (use! n "untranslated")
                                      (if (string-null? (string-trim-both why))
                                          (list (e "untranslated word ~a needs a reason" n)) '())))
                             (x (list (e "untranslated entry ~s should be (word-number \"reason\")" x))))
                           untranslated)
               (if literal
                   (filter-map (lambda (w)
                                 (and (not (hash-ref used (word-n w)))
                                      (e "Greek word ~a (~a) is not translated; add it to a literal segment or to (untranslated (~a \"reason\"))"
                                         (word-n w) (word-text* w) (word-n w))))
                               words)
                   '())
               (match readable
                 (#f (list (e "missing (readable \"...\")")))
                 (((? string? text)) (append (readable-ambiguity text) (avoid-errors text)))
                 ((rsegs ..1)
                  (append
                   (append-map (match-lambda
                                 (((? string?) refs ...)
                                  (filter-map (lambda (r) (and (not (word-at (ref-n r)))
                                                               (e "readable segment refers to Greek word ~s, which this verse does not have" (ref-n r))))
                                              refs))
                                 (x (list (e "malformed readable segment ~s" x))))
                               rsegs)
                   (append-map (lambda (s) (ambiguity "readable" s)) rsegs)
                   (avoid-errors (segments-text (filter segment? rsegs))))))
               (append-map (match-lambda
                             (((? string?)) '())
                             (((? integer? n) (? string?))
                              (if (word-at n) '() (list (e "note on Greek word ~a, which this verse does not have" n))))
                             (x (list (e "note should be (note \"text\") or (note word-number \"text\"), got ~s" (cons 'note x)))))
                           (verse-fields form 'note)))))))))
    (append-map
     (lambda (form)
       (match form
         (('note (? string?)) '())
         (('verse (or (? integer?) (? string?)) . _) (check-verse form))
         (_ (list (err "top level" "expected (note \"...\") or (verse N ...), got ~s" form)))))
     forms)))
