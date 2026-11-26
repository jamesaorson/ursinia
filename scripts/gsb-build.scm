;; Copyright (C) 2026
;;
;; Build the Greek Source Bible word tables (gsb/greek/NN-<id>.tsv) and reports
;; (gsb/reports/) from the pinned sources under gsb/sources/. Deterministic: a
;; file whose content would not change is left untouched.
;;
;; Invoked through ./scripts/gsb-build.sh, which anchors the working directory to
;; the repo root. See gsb/README.md for the output format.

(use-modules (scripts lib gsb)
             (ice-9 ftw)
             (ice-9 regex)
             (ice-9 format)
             (ice-9 getopt-long)
             (ice-9 match)
             (srfi srfi-1)
             (srfi srfi-13))

(define %program "gsb-build")

(define (usage port)
  (format port "Usage: ./scripts/gsb-build.sh [OPTIONS]~%~%")
  (format port "Build gsb/greek/*.tsv (one row per Greek word) and gsb/reports/ from the~%")
  (format port "sources in gsb/sources/ (download them first with `make gsb/fetch`).~%~%")
  (format port "Options:~%")
  (format port "  -h, --help    Show this help~%")
  (format port "  -c, --check   Write nothing; exit non-zero if any output is out of date~%~%")
  (format port "Examples:~%")
  (format port "  make gsb          Build~%")
  (format port "  make gsb/check    Verify the committed output is current~%"))

(define (die fmt . args)
  (format (current-error-port) "~a: ~?~%" %program fmt args)
  (exit 1))

(define (source path)
  (let ((full (string-append "gsb/sources/" path)))
    (unless (file-exists? full)
      (die "source missing: ~a~%  run `make gsb/fetch` to download the pinned sources" full))
    full))

(define (parse-strong s)
  (let ((n (string->number (car (string-split s #\&)))))
    (and n (> n 0) n)))

;;; ---------------------------------------------------------------------------
;;; Books
;;; ---------------------------------------------------------------------------

(define %book-columns '(nn id english greek testament deuterocanonical role source notes))

(define (read-books)
  (map (lambda (line) (map cons %book-columns (split-tab line)))
       (cdr (read-lines "gsb/books.tsv"))))

(define (book-ref book field) (assq-ref book field))

(define (book-sources book)
  "Alist of source name to list of codes, from the source column (\"nestle:Matt tr:MT\")."
  (map (lambda (item)
         (let ((parts (string-split item #\:)))
           (cons (car parts) (string-split (cadr parts) #\,))))
       (string-tokenize (book-ref book 'source))))

;;; ---------------------------------------------------------------------------
;;; Nestle 1904 (NT base)
;;; ---------------------------------------------------------------------------

;; Hash: book code -> list of ((chapter . verse) . list of word rows), in order.
(define (read-nestle)
  (let ((books (make-hash-table)))
    (for-each
     (lambda (line)
       (match (split-tab line)
         ((ref text morph _ strong lemma . _)
          (let* ((space (string-index ref #\space))
                 (code (substring ref 0 space))
                 (cv (map string->number (string-split (substring ref (+ space 1)) #\:)))
                 (key (cons (car cv) (cadr cv)))
                 (parts (split-punct text))
                 (row (make-word (first parts) (normalize-elision (second parts)) (third parts)
                                 lemma (parse-strong strong) morph '()))
                 (verses (hash-ref books code '())))
            (hash-set! books code
                       (if (and (pair? verses) (equal? (caar verses) key))
                           (cons (cons key (cons row (cdar verses))) (cdr verses))
                           (cons (list key row) verses)))))))
     (cdr (read-lines (source "nestle1904/Nestle1904.csv"))))
    (hash-for-each (lambda (code verses)
                     (hash-set! books code
                                (reverse (map (lambda (v) (cons (car v) (reverse (cdr v)))) verses))))
                   books)
    books))

;;; ---------------------------------------------------------------------------
;;; Robinson's Textus Receptus (Scrivener 1894 readings)
;;; ---------------------------------------------------------------------------

(define (verse-marker? tok)
  (and (string-index tok #\:) (string-every (lambda (c) (or (char-numeric? c) (char=? c #\:))) tok)))

(define (read-tr code)
  "Alist of ((chapter . verse) . list of (greek strong morph)) for TR book CODE.
Where the file gives | A | B | the B reading (Scrivener 1894) is taken."
  (let loop ((toks (string-tokenize (string-join (read-lines (source (string-append "tr/" code ".UTR"))) " ")))
             (state 'text) (key #f) (words '()) (verses '()))
    (define (close) (if key (cons (cons key (reverse words)) verses) verses))
    (define (tag-last field value)
      ;; Attach a Strong's number or parsing to the latest word that lacks one.
      (match words
        (((greek strong morph) . rest)
         (cond
          ((and (eq? field 'strong) (not strong)) (cons (list greek value morph) rest))
          ((and (eq? field 'morph) (not morph)) (cons (list greek strong value) rest))
          (else words)))
        (_ words)))
    (if (null? toks)
        (reverse (close))
        (let ((tok (car toks)) (rest (cdr toks)))
          (cond
           ((string=? tok "|")
            (loop rest (case state ((text) 'a) ((a) 'b) (else 'text)) key words verses))
           ((eq? state 'a) (loop rest state key words verses))
           ((string-prefix? "(" tok) (loop rest state key words verses))
           ((verse-marker? tok)
            (let ((cv (map string->number (string-split tok #\:))))
              (loop rest state (cons (car cv) (cadr cv)) '() (close))))
           ((string-prefix? "{" tok)
            (loop rest state key (tag-last 'morph (string-trim-both tok (char-set #\{ #\}))) verses))
           ((string->number tok)
            (loop rest state key (tag-last 'strong (string->number tok)) verses))
           (else
            (let ((greek (translit->greek tok)))
              (unless greek (die "unexpected token ~s in tr/~a.UTR" tok code))
              (loop rest state key (cons (list greek #f #f) words) verses))))))))

;;; ---------------------------------------------------------------------------
;;; Robinson-Pierpont (accent source only)
;;; ---------------------------------------------------------------------------

(define (strip-braces s)
  "Remove the {...} apparatus notes from an RP verse."
  (let loop ((chars (string->list s)) (depth 0) (acc '()))
    (match chars
      (() (list->string (reverse acc)))
      ((#\{ . rest) (loop rest (+ depth 1) acc))
      ((#\} . rest) (loop rest (max 0 (- depth 1)) acc))
      ((c . rest) (loop rest depth (if (zero? depth) (cons c acc) acc))))))

(define (read-rp codes)
  "Hash (chapter . verse) -> list of accented words, from RP files CODES."
  (let ((verses (make-hash-table)))
    (for-each
     (lambda (code)
       (for-each
        (lambda (line)
          (let* ((c1 (string-index line #\,))
                 (c2 (string-index line #\, (+ c1 1)))
                 (key (cons (string->number (substring line 0 c1))
                            (string->number (substring line (+ c1 1) c2))))
                 (text (strip-braces (string-trim-both (substring line (+ c2 1)) #\")))
                 (words (filter (lambda (w) (string-any char-alphabetic? w))
                                (map (lambda (t) (normalize-elision (second (split-punct t))))
                                     (string-tokenize text)))))
            (hash-set! verses key (append (hash-ref verses key '()) words))))
        (cdr (read-lines (source (string-append "rp/" code ".csv"))))))
     codes)
    verses))

;;; ---------------------------------------------------------------------------
;;; NT-derived lexical tables (CC0 / public domain data only)
;;; ---------------------------------------------------------------------------

(define (build-lexicon nestle tr-books)
  "Returns (values strong->lemma form-table stripped-table):
strong->lemma: Strong's number -> most frequent Nestle lemma;
form-table: accented form (lowercase, acute) -> hash of (lemma . strong) -> count;
stripped-table: fold-key -> hash of (lemma . strong) -> count, adding TR forms."
  (let ((by-strong (make-hash-table))
        (forms (make-hash-table))
        (stripped (make-hash-table)))
    (define (count! table key value)
      (let ((inner (or (hash-ref table key)
                       (let ((h (make-hash-table))) (hash-set! table key h) h))))
        (hash-inc! inner value)))
    (hash-for-each
     (lambda (code verses)
       (for-each (lambda (verse)
                   (for-each (lambda (w)
                               (let ((entry (cons (word-lemma w) (word-strong w))))
                                 (when (word-strong w) (count! by-strong (word-strong w) (word-lemma w)))
                                 (count! forms (spelling-key (word-text w)) entry)
                                 (count! stripped (fold-key (word-text w)) entry)))
                             (cdr verse)))
                 verses))
     nestle)
    (let ((strong->lemma (make-hash-table)))
      (hash-for-each (lambda (strong lemmas) (hash-set! strong->lemma strong (car (most-frequent lemmas))))
                     by-strong)
      (for-each (lambda (verses)
                  (for-each (lambda (verse)
                              (for-each (match-lambda
                                          ((greek strong _)
                                           (let ((lemma (and strong (hash-ref strong->lemma strong))))
                                             (when lemma
                                               (count! stripped (fold-key greek) (cons lemma strong))))))
                                        (cdr verse)))
                            verses))
                tr-books)
      (values strong->lemma forms stripped))))

;;; NT merge: Nestle 1904 base + longer TR readings
;;; ---------------------------------------------------------------------------

(define (tr-key w) (compare-key (first w)))
(define (base-key w) (compare-key (word-text w)))

(define (same-word? b t)
  ;; Pairing weight: equal letters (after the spelling-noise folding in
  ;; compare-key) and Strong's number 3, equal letters 2 (Luke 2:38 αὕτη αὐτῇ:
  ;; the base αὐτῇ pairs with the TR αὐτῇ, not αὕτη), the same Strong's number
  ;; with the same first two letters 1 (Δαυείδ/δαβιδ), else no match.
  (let ((letters? (string=? (car b) (car t)))
        (strong? (and (cdr b) (eqv? (cdr b) (cdr t)))))
    (cond
     ((and letters? strong?) 3)
     (letters? 2)
     ((and strong? (>= (string-length (car b)) 2) (>= (string-length (car t)) 2)
           (<= (abs (- (string-length (car b)) (string-length (car t)))) 2)
           (string=? (substring (car b) 0 2) (substring (car t) 0 2)))
      1)
     (else #f))))

(define (key+strong-base w) (cons (base-key w) (word-strong w)))
(define (key+strong-tr w) (cons (tr-key w) (second w)))

(define (lcs-ratio keys window)
  "Share of KEYS found, in order, in WINDOW (lists of compare keys)."
  (if (null? keys)
      0
      (/ (count (lambda (op) (eq? (car op) '=))
                (lcs-ops (list->vector keys) (list->vector window) string=?))
         (length keys))))

(define (repair-accent greek strong rp-verse rp-near nestle-spellings any-spellings proper)
  "Accented spelling for unaccented TR word GREEK, or #f: the one matching
spelling in the same RP verse, else in the neighboring RP verses (RP's verse
breaks sometimes differ), else the one Nestle spelling for these letters and
Strong's number, else the one Nestle/RP spelling for these letters."
  (define key (fold-key greek))
  (define known
    ;; Nestle's spellings for these letters and this Strong's number, if any:
    ;; an RP candidate must be one of them (so εν for G1722 never becomes ἕν).
    (let ((inner (and strong (hash-ref nestle-spellings (cons key strong)))))
      (and inner (hash-map->list (lambda (s n) (string-downcase s)) inner))))
  (define (plain w) (drop-throwback (grave->acute w)))
  (define (one-in words)
    (let ((found (delete-duplicates
                  (filter (lambda (w) (and (string=? (fold-key w) key)
                                           (or (not known) (member (string-downcase (plain w)) known))))
                          words)
                  (lambda (a b) (string=? (string-downcase (plain a)) (string-downcase (plain b)))))))
      (and (= 1 (length found))
           (let ((s (plain (car found))))
             (if (hash-ref proper (spelling-key s)) s (string-downcase s))))))
  (or (one-in rp-verse)
      (one-in rp-near)
      (and strong (unique-spelling nestle-spellings (cons key strong) #:clitics? #t))
      (unique-spelling any-spellings key)))

(define (pos morph)
  "Part of speech of a Robinson parsing code (V-PAI-3S -> V)."
  (car (string-split (or morph "") #\-)))

(define (key<? a b) (or (< (car a) (car b)) (and (= (car a) (car b)) (< (cdr a) (cdr b)))))

(define (merge-book book nestle-verses tr-verses rp nestle-spellings any-spellings proper strong->lemma)
  "Merge one NT book. Returns (values verse-rows variant-rows unaccented-rows).
Pass 1 diffs every verse the two texts share; pass 2 classifies the hunks.
A TR insertion (or TR-only verse) that matches Nestle words the TR lacks in a
neighboring verse is a verse-boundary difference (\"moved\"), not a longer
reading, and the base is kept."
  (let* ((id (book-ref book 'id))
         (tr (alist->hash-table tr-verses))
         (base (alist->hash-table nestle-verses))
         (keys (sort (delete-duplicates (append (map car nestle-verses) (map car tr-verses))) key<?))
         (diffs (alist->hash-table
                 (filter-map
                  (lambda (key)
                    (let ((b (hash-ref base key)) (t (hash-ref tr key)))
                      (and b t
                           (let ((ops (lcs-ops (list->vector (map key+strong-base b))
                                               (list->vector (map key+strong-tr t))
                                               same-word?)))
                             (cons key (cons ops (diff-hunks ops)))))))
                  keys)))
         (omitted (unmatched-base keys base diffs #t))
         (unmatched (unmatched-base keys base diffs #f))
         (variants '()))
    (define (ref-of key) (format #f "~a.~a.~a" id (car key) (cdr key)))
    (define (neighbors key)
      (let* ((before (filter (lambda (k) (key<? k key)) keys))
             (after (filter (lambda (k) (key<? key k)) keys)))
        (append (take-right before (min 2 (length before))) (take after (min 2 (length after))))))
    (define (moved? tkeys key)
      ;; Short runs need a pure omission next door; longer runs and whole verses
      ;; may also match base words the TR replaced there (2 Cor 13:12-14).
      (let ((pool (if (>= (length tkeys) 3) unmatched omitted)))
        (>= (lcs-ratio tkeys (append-map (lambda (k) (hash-ref pool k)) (neighbors key))) 4/5)))
    (define (rp-near key)
      (append-map (lambda (k) (hash-ref rp k '()))
                  (list (cons (car key) (- (cdr key) 1)) (cons (car key) (+ (cdr key) 1)))))
    (define (restored key w)
      (match w
        ((greek strong morph)
         (let ((accented (repair-accent greek strong (hash-ref rp key '()) (rp-near key)
                                        nestle-spellings any-spellings proper)))
           (make-word "" (or accented greek) ""
                      (or (and strong (hash-ref strong->lemma strong)) "")
                      strong (or morph "")
                      (if accented '("tr") '("tr" "accent?")))))))
    (define (note! key kind base-words tr-words)
      (set! variants (cons (list (ref-of key) kind
                                 (string-join (map (lambda (w) (string-append (word-pre w) (word-text w) (word-post w))) base-words) " ")
                                 (string-join (map word-text (settle-accents tr-words)) " "))
                           variants)))
    (define (settle-accents words)
      ;; Restored words: grave on an oxytone directly followed by another word.
      (let loop ((ws words) (acc '()))
        (match ws
          (() (reverse acc))
          ((w . rest)
           (loop rest
                 (cons (if (and (member "tr" (word-flags w)) (not (member "accent?" (word-flags w))))
                           (word-with w 'word (contextual-accent (grave->acute (word-text w))
                                                                 (or (null? rest)
                                                                     (not (string-null? (word-post w)))
                                                                     (not (string-null? (word-pre (car rest)))))))
                           w)
                       acc))))))
    (define (merge-verse key b t)
      (match (hash-ref diffs key)
        ((ops . hunks)
         (let* ((bv (list->vector b)) (tv (list->vector t))
                (last-base (- (vector-length bv) 1))
                (removed (append-map (lambda (h) (map (lambda (i) (base-key (vector-ref bv i))) (second h))) hunks))
                ;; Base words paired with a differently spelled TR word (same Strong's):
                ;; a TR insertion of the same word is a misalignment, not a new reading.
                (loose (filter-map (match-lambda
                                     (('= i j) (let ((k (base-key (vector-ref bv i))))
                                                 (and (not (string=? k (tr-key (vector-ref tv j)))) k)))
                                     (_ #f))
                                   ops))
                ;; Base words the TR lacks outright, with their part of speech.
                (omits (append-map (match-lambda
                                     ((after dels ()) (map (lambda (i) (cons i (pos (word-morph (vector-ref bv i))))) dels))
                                     (_ '()))
                                   hunks))
                (restore (make-hash-table))
                (punct-moves '()))
           (define (split-substitution? after ins)
             ;; Matt 13:28 εἶπον αὐτῷ / αὐτῷ λέγουσιν: the TR word stands where the
             ;; base has a different word of the same part of speech one or two
             ;; words away, so it replaces that word rather than adding to it.
             (let ((near (filter (lambda (o) (<= (abs (- (car o) (+ after 1/2))) 5/2)) omits)))
               (and (pair? near)
                    (equal? (sort (map cdr near) string<?)
                            (sort (map (lambda (j) (pos (third (vector-ref tv j)))) ins) string<?)))))
           (for-each
            (match-lambda
              ((after dels ins)
               (let ((bw (map (lambda (i) (vector-ref bv i)) dels))
                     (tw (map (lambda (j) (restored key (vector-ref tv j))) ins))
                     (tkeys (map (lambda (j) (tr-key (vector-ref tv j))) ins)))
                 (cond
                  ((null? ins) (note! key "tr-omits" bw '()))
                  ((pair? dels)
                   (note! key (if (equal? (sort (map base-key bw) string<?) (sort tkeys string<?)) "order" "subst")
                          bw tw))
                  ((any (lambda (k) (or (member k removed) (member k loose))) tkeys) (note! key "order" '() tw))
                  ((moved? tkeys key) (note! key "moved" '() tw))
                  ((split-substitution? after ins) (note! key "subst-split" '() tw))
                  (else
                   (note! key "insert" '() tw)
                   (for-each (lambda (j w) (hash-set! restore j w)) ins tw)
                   (when (and (>= after 0) (not (string-null? (word-post (vector-ref bv after)))))
                     (set! punct-moves (cons (list after (last ins) (length ins)) punct-moves))))))))
            hunks)
           (let* ((words (filter-map (match-lambda
                                       (('= i j) (vector-ref bv i))
                                       (('- i) (vector-ref bv i))
                                       (('+ j) (hash-ref restore j)))
                                     ops))
                  ;; Punctuation around an insertion that follows a punctuated base
                  ;; word. A long insertion after anything but a comma is its own
                  ;; clause: the base word keeps its mark (Matt 6:13 πονηροῦ. ὅτι
                  ;; ...), and at verse end the insertion gets a copy (ἀμήν.).
                  ;; Otherwise the mark moves to the end of the insertion (Rom 9:32
                  ;; ἔργων νόμου·, Rev 22:21 πάντων ὑμῶν ἀμήν.).
                  (edits (map (match-lambda
                                ((after j len)
                                 (let* ((donor (vector-ref bv after))
                                        (punct (word-post donor))
                                        (clause? (and (>= len 3) (not (string=? (string-trim-right punct) ",")))))
                                   (list donor (hash-ref restore j)
                                         (if clause? punct "")
                                         (if (and clause? (< after last-base)) "" punct)))))
                              punct-moves)))
             (settle-accents
              (map (lambda (w)
                     (let ((as-donor (find (lambda (e) (eq? w (first e))) edits))
                           (as-receiver (find (lambda (e) (eq? w (second e))) edits)))
                       (cond
                        (as-donor (word-with w 'post (third as-donor)))
                        ((and as-receiver (not (string-null? (fourth as-receiver))))
                         (add-flags (word-with w 'post (fourth as-receiver)) '("punct")))
                        (else w))))
                   words)))))))
    (let ((rows
           (append-map
            (lambda (key)
              (let ((b (hash-ref base key)) (t (hash-ref tr key)))
                (cond
                 ((not t) (list (cons key b)))
                 ((not b)
                  (let ((words (map (lambda (w) (restored key w)) t)))
                    (if (moved? (map tr-key t) key)
                        (begin (note! key "moved-verse" '() words) '())
                        (begin (note! key "verse" '() words)
                               (list (cons key (settle-accents
                                                (map (lambda (w) (add-flags w '("tr-verse"))) words))))))))
                 (else (list (cons key (merge-verse key b t)))))))
            keys)))
      (values rows (reverse variants)
              (append-map (match-lambda
                            ((key . words)
                             (filter-map (lambda (w n)
                                           (and (member "accent?" (word-flags w))
                                                (list (ref-of key) n (word-text w) (strong-label (word-strong w)))))
                                         words (iota (length words) 1))))
                          rows)))))

(define (unmatched-base keys base diffs pure-only?)
  "Hash key -> compare keys of the base words the TR does not match in that
verse: all of them where the TR lacks the verse, else those in hunks the TR
omits outright (PURE-ONLY?) or omits or replaces."
  (alist->hash-table
   (map (lambda (key)
          (cons key
                (let ((d (hash-ref diffs key)) (b (hash-ref base key)))
                  (cond
                   ((not b) '())
                   ((not d) (map base-key b))
                   (else (append-map (match-lambda
                                       ((after dels ins)
                                        (if (or (null? ins) (not pure-only?))
                                            (map (lambda (i) (base-key (list-ref b i))) dels)
                                            '())))
                                     (cdr d)))))))
        keys)))

(define (alist->hash-table alist)
  (let ((h (make-hash-table)))
    (for-each (lambda (p) (hash-set! h (car p) (cdr p))) alist)
    h))

;;; ---------------------------------------------------------------------------
;;; Lexicon: gsb/lexicon/strongs.tsv (Dodson + Strong's, both CC0/PD)
;;; ---------------------------------------------------------------------------

(define (unquote-csv s)
  (let ((s (string-trim-both s)))
    (if (and (>= (string-length s) 2) (string-prefix? "\"" s) (string-suffix? "\"" s))
        (let loop ((chars (string->list (substring s 1 (- (string-length s) 1)))) (acc '()))
          (match chars
            (() (list->string (reverse acc)))
            ((#\" #\" . rest) (loop rest (cons #\" acc)))
            ((c . rest) (loop rest (cons c acc)))))
        s)))

(define (read-dodson)
  "Hash Strong's number -> (brief longer)."
  (let ((table (make-hash-table)))
    (for-each (lambda (line)
                (match (map unquote-csv (split-tab line))
                  ((strong _ _ brief longer . _)
                   (let ((n (string->number strong 10)))
                     (when (and n (not (hash-ref table n)))
                       (hash-set! table n (list brief longer)))))
                  (_ #f)))
              (cdr (read-lines (source "dodson/dodson.csv"))))
    table))

(define (xml-text s)
  "Plain text of an XML fragment: <strongsref strongs=\"N\"/> becomes GN, other
tags are dropped, whitespace is collapsed."
  (let* ((s (regexp-substitute/global #f "<strongsref[^>]*strongs=\"0*([0-9]+)\"[^>]*/>" s 'pre "G" 1 'post))
         (s (regexp-substitute/global #f "<[^>]*>" s 'pre 'post))
         (s (regexp-substitute/global #f "&amp;" s 'pre "&" 'post)))
    (string-join (string-tokenize s) " ")))

(define (read-strongs)
  "Hash Strong's number -> (headword definition)."
  (let ((table (make-hash-table))
        (text (string-join (read-lines (source "strongs/strongsgreek.xml")) "\n")))
    (for-each (lambda (m)
                (let* ((entry (match:substring m 0))
                       (n (string->number (match:substring m 1) 10))
                       (head (string-match "unicode=\"([^\"]*)\"" entry))
                       (def (string-match "<strongs_def>(.*)</strongs_def>" entry)))
                  (hash-set! table n (list (if head (string-normalize-nfc (match:substring head 1)) "")
                                           (if def (xml-text (match:substring def 1)) "")))))
              (list-matches "<entry strongs=\"0*([0-9]+)\">([^<]|<[^/]|</[^e])*</entry>" text))
    table))

(define (lexicon-table strong->lemma)
  (let ((dodson (read-dodson)) (strongs (read-strongs)))
    (tsv-lines '("strong" "lemma" "strongs_headword" "gloss" "definition" "definition_source")
               (filter-map
                (lambda (n)
                  (let ((d (hash-ref dodson n)) (s (hash-ref strongs n)))
                    (and (or d s)
                         (list (strong-label n)
                               (or (hash-ref strong->lemma n) (if s (first s) ""))
                               (if s (first s) "")
                               (if d (first d) "")
                               (cond ((and d (not (string-null? (second d)))) (second d))
                                     (s (second s))
                                     (else ""))
                               (cond ((and d (not (string-null? (second d)))) "dodson")
                                     (s "strongs")
                                     (else ""))))))
                (iota 5624 1)))))

;;; ---------------------------------------------------------------------------
;;; Main
;;; ---------------------------------------------------------------------------

(define (main args)
  (let* ((options (catch #t
                    (lambda () (getopt-long args '((help (single-char #\h) (value #f))
                                                     (check (single-char #\c) (value #f)))))
                    (lambda (key . rest)
                      (format (current-error-port) "~a: unknown option~%~%" %program)
                      (usage (current-error-port))
                      (exit 2))))
         (check? (option-ref options 'check #f)))
    (when (option-ref options 'help #f) (usage (current-output-port)) (exit 0))
    (unless (null? (option-ref options '() '()))
      (format (current-error-port) "~a: unexpected arguments ~a~%~%" %program (option-ref options '() '()))
      (usage (current-error-port))
      (exit 2))
    (let* ((books (read-books))
           (nt-books (filter (lambda (b) (string=? (book-ref b 'testament) "NT")) books))
           (ot-books (filter (lambda (b) (string=? (book-ref b 'testament) "OT")) books))
           (nestle (read-nestle))
           (tr-books (map (lambda (b) (read-tr (car (assoc-ref (book-sources b) "tr")))) nt-books))
           (rps (map (lambda (b) (read-rp (assoc-ref (book-sources b) "rp"))) nt-books))
           (nestle-spellings (make-hash-table))
           (any-spellings (make-hash-table))
           (case-seen (make-hash-table))
           (outputs '()))
      (define (output! path text) (set! outputs (cons (cons path text) outputs)))
      (define (book-path b) (format #f "gsb/greek/~a-~a.tsv" (book-ref b 'nn) (book-ref b 'id)))
      (define (see! s)
        (index-spelling! any-spellings (fold-key s) s)
        (let ((k (spelling-key s)))
          (hash-set! case-seen k (and (hash-ref case-seen k #t) (capitalized? s)))))
      (hash-for-each (lambda (code verses)
                       (for-each (lambda (v)
                                   (for-each (lambda (w)
                                               (index-spelling! nestle-spellings
                                                                (cons (fold-key (word-text w)) (word-strong w))
                                                                (word-text w))
                                               (see! (word-text w)))
                                             (cdr v)))
                                 verses))
                     nestle)
      (for-each (lambda (rp) (hash-for-each (lambda (k words) (for-each see! words)) rp)) rps)
      (call-with-values (lambda () (build-lexicon nestle tr-books))
        (lambda (strong->lemma forms stripped)
          ;; ---------------- NT
          (format #t "NT: merging Nestle 1904 with the Textus Receptus~%")
          (let ((proper (make-hash-table)) (all-variants '()) (all-unaccented '()))
            (hash-for-each (lambda (k always-cap) (when always-cap (hash-set! proper k #t))) case-seen)
            (for-each
             (lambda (b tr rp)
               (let ((code (car (assoc-ref (book-sources b) "nestle"))))
                 (call-with-values
                     (lambda () (merge-book b (or (hash-ref nestle code) (die "Nestle1904 has no book ~a" code))
                                            tr rp nestle-spellings any-spellings proper strong->lemma))
                   (lambda (rows variants unaccented)
                     (output! (book-path b) (book-table (book-ref b 'id) rows))
                     (set! all-variants (append all-variants variants))
                     (set! all-unaccented (append all-unaccented unaccented))))))
             nt-books tr-books rps)
            (output! "gsb/reports/nt-variants.tsv"
                     (tsv-lines '("ref" "kind" "nestle1904" "tr") all-variants))
            (output! "gsb/reports/nt-unaccented.tsv"
                     (tsv-lines '("ref" "n" "word" "strong") all-unaccented)))
          ;; ---------------- Lexicon
          (output! "gsb/lexicon/strongs.tsv" (lexicon-table strong->lemma))
          ;; ---------------- LXX
          (let* ((present (filter (lambda (b) (file-exists? (lxx-path b))) ot-books))
                 (books+verses (map (lambda (b)
                                      (cons b (map (match-lambda ((key . tokens) (cons key (lxx-verse-words tokens))))
                                                   (read-transcription (lxx-path b)))))
                                    present)))
            (format #t "LXX: ~a of ~a books transcribed~%" (length present) (length ot-books))
            ;; Decapitalize over the whole transcribed corpus at once, so every
            ;; book's spellings count; any-spellings already holds the NT's.
            (call-with-values
                (lambda () (decapitalize (append-map (lambda (bv)
                                                       (map (match-lambda ((key . words) (cons (cons (book-ref (car bv) 'id) key) words)))
                                                            (cdr bv)))
                                                     books+verses)
                                         any-spellings))
              (lambda (tagged caps-report)
                (let ((unmatched (make-hash-table)) (all-types (make-hash-table)) (all-typed (make-hash-table)))
                  (define coverage
                    (map (lambda (b)
                           (let* ((id (book-ref b 'id))
                                  (verses (filter-map (match-lambda
                                                        (((bid . key) . words)
                                                         (and (string=? bid id)
                                                              (cons key (map (lambda (w) (lemmatize forms stripped w)) words)))))
                                                      tagged))
                                  (words (append-map cdr verses))
                                  (types (make-hash-table)) (typed (make-hash-table)))
                             (if (not (member b present))
                                 (list id "not yet transcribed" 0 0 0 0 0)
                                 (begin
                                   (output! (book-path b) (book-table id verses))
                                   (for-each (lambda (w)
                                               (let ((k (spelling-key (word-text w))))
                                                 (hash-set! types k #t) (hash-set! all-types k #t)
                                                 (if (string-null? (word-lemma w))
                                                     (hash-inc! unmatched k)
                                                     (begin (hash-set! typed k #t) (hash-set! all-typed k #t)))))
                                             words)
                                   (list id "transcribed" (length words)
                                         (count (lambda (w) (not (string-null? (word-lemma w)))) words)
                                         (count (lambda (w) (word-strong w)) words)
                                         (hash-count (const #t) types) (hash-count (const #t) typed))))))
                         ot-books))
                  (define (row id status tokens lemma strong types typed)
                    (list id status tokens lemma (percent lemma tokens) strong (percent strong tokens)
                          types typed (percent typed types)))
                  (let ((sums (fold (lambda (r acc) (map + (cddr r) acc)) '(0 0 0 0 0) coverage)))
                    (output! "gsb/reports/lxx-coverage.tsv"
                             (tsv-lines '("book" "status" "tokens" "with_lemma" "lemma_pct" "with_strong" "strong_pct"
                                          "types" "types_with_lemma" "type_pct")
                                        (append (map (lambda (r) (apply row r)) coverage)
                                                (list (row "TOTAL" "" (first sums) (second sums) (third sums)
                                                           (hash-count (const #t) all-types)
                                                           (hash-count (const #t) all-typed)))))))
                  (output! "gsb/reports/lxx-unmatched-forms.tsv"
                           (tsv-lines '("rank" "form" "count")
                                      (let* ((top (hash->sorted-alist unmatched by-count-then-key))
                                             (n (min 200 (length top))))
                                        (map (lambda (p i) (list i (car p) (cdr p))) (take top n) (iota n 1)))))
                  (output! "gsb/reports/lxx-capitals.tsv"
                           (tsv-lines '("ref" "n" "swete" "status" "restored")
                                      (map (match-lambda
                                             (((id . (ch . v)) n caps status restored)
                                              (list (format #f "~a.~a.~a" id ch v) n caps status restored)))
                                           caps-report)))))))))
      (write-outputs (reverse outputs) check?))))

(define (lxx-path b) (format #f "gsb/sources/swete/~a-~a.tsv" (book-ref b 'nn) (book-ref b 'id)))

(define (write-outputs outputs check?)
  (let* ((expected (map car outputs))
         (existing (append-map (lambda (dir)
                                 (if (file-exists? dir)
                                     (map (lambda (f) (string-append dir "/" f))
                                          (scandir dir (lambda (f) (string-suffix? ".tsv" f))))
                                     '()))
                               '("gsb/greek" "gsb/reports" "gsb/lexicon")))
         (stray (filter (lambda (p) (not (member p expected))) existing))
         (results (map (match-lambda ((path . text) (cons path (write-if-changed path text check?))))
                       outputs)))
    (for-each (lambda (p)
                (format #t "  ~a: ~a~%" p (if check? "STRAY (no longer produced by the build)" "removed"))
                (unless check? (delete-file p)))
              stray)
    (for-each (match-lambda ((path . result) (unless (eq? result 'unchanged) (format #t "  ~a: ~a~%" path result))))
              results)
    (format #t "~a: ~a files, ~a changed~%" %program (length results)
            (+ (length stray) (count (lambda (r) (not (eq? (cdr r) 'unchanged))) results)))
    (when (and check? (or (pair? stray) (any (lambda (r) (eq? (cdr r) 'stale)) results)))
      (format (current-error-port) "~a: gsb/ output is out of date -- run `make gsb` to rebuild~%" %program)
      (exit 1))))

(main (command-line))
