;; Copyright (C) 2026
;;
;; Pure helpers for the Greek Source Bible (GSB) build: Greek string
;; normalization, word/punctuation splitting, the LCS word diff used to merge the
;; Textus Receptus into the Nestle 1904 base, and the Textus Receptus
;; transliteration. Kept free of file I/O so scripts/lib/test/gsb/test.scm can
;; exercise it directly.

(define-module (scripts lib gsb)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 textual-ports)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:use-module (ice-9 format)
  #:use-module (ice-9 match)
  #:export (hash-inc!
            hash->sorted-alist
            by-count-then-key
            most-frequent
            percent
            tsv-lines
            strong-label
            make-word word-pre word-text word-post word-lemma word-strong word-morph word-flags
            word-with
            add-flags
            book-table
            spelling-key
            drop-throwback
            capitalized?
            index-spelling!
            unique-spelling
            contextual-accent
            lookup-lemma
            lemmatize
            read-transcription
            lxx-verse-words
            decapitalize
            strip-marks
            fold-key
            compare-key
            grave->acute
            normalize-elision
            word-char?
            split-punct
            all-caps?
            capitalize-first
            lcs-ops
            diff-hunks
            translit->greek
            final-sigma
            read-lines
            split-tab
            string->tsv-field
            write-if-changed))

;;; ---------------------------------------------------------------------------
;;; Greek strings
;;; ---------------------------------------------------------------------------

(define (combining? c)
  (eq? (char-general-category c) 'Mn))

(define (memoize f)
  ;; Unicode normalization is the slow part of the build, and the corpus has far
  ;; fewer distinct words than tokens.
  (let ((cache (make-hash-table)))
    (lambda (s)
      (or (hash-ref cache s)
          (let ((r (f s))) (hash-set! cache s r) r)))))

(define strip-marks
  (memoize
   (lambda (s)
     "Remove every accent, breathing, diaeresis and iota subscript from S."
     (string-normalize-nfc
      (string-filter (lambda (c) (not (combining? c))) (string-normalize-nfd s))))))

(define %elision-marks '(#\x2019 #\x1FBD #\x02BC #\x0027))

(define (normalize-elision s)
  "Write every elision mark in S as U+2019, the one Nestle 1904 uses."
  (string-map (lambda (c) (if (memv c %elision-marks) #\x2019 c)) s))

;; Accent-stripped, lowercase, final-sigma-folded letters. Elision marks are
;; dropped, so ἀπ’ and απ compare equal.
(define fold-key
  (memoize
   (lambda (s)
     (string-map (lambda (c) (if (char=? c #\ς) #\σ c))
                 (string-filter (lambda (c) (not (memv c %elision-marks)))
                                (string-downcase (strip-marks s)))))))

;; Spelling noise that must not pass for a textual variant when the base text is
;; compared with the Textus Receptus: movable nu (εἰσίν/εἰσί, εἶπεν/εἶπε) and
;; the two common adverbs with an optional final sigma.
(define %optional-sigma '("ουτωσ" "αχρισ" "μεχρισ"))

(define (compare-key s)
  (let* ((k (fold-key s))
         (n (string-length k)))
    (cond
     ((member k %optional-sigma) (substring k 0 (- n 1)))
     ((and (>= n 4)
           (char=? (string-ref k (- n 1)) #\ν)
           (memv (string-ref k (- n 2)) '(#\ε #\ι)))
      (substring k 0 (- n 1)))
     (else k))))

(define grave->acute
  (memoize
   (lambda (s)
     (string-normalize-nfc
      (string-map (lambda (c) (if (char=? c #\x0300) #\x0301 c))
                  (string-normalize-nfd s))))))

(define (word-char? c)
  (or (char-alphabetic? c) (combining? c) (memv c %elision-marks)))

(define (split-punct s)
  "Split S into (pre word post): the leading and trailing runs of non-word
characters around the word proper. Punctuation inside the word stays put."
  (let* ((n (string-length s))
         (start (or (string-index s word-char?) n))
         (end (if (= start n) n (+ 1 (string-rindex s word-char?)))))
    (list (substring s 0 start) (substring s start end) (substring s end n))))

(define (all-caps? s)
  "True when S is written in unaccented capitals, the way Swete prints the
opening word(s) of a chapter."
  (let ((letters (string-filter char-alphabetic? s)))
    (and (> (string-length letters) 0)
         (string-every char-upper-case? letters)
         (or (> (string-length letters) 1)
             (not (string-any combining? (string-normalize-nfd s)))))))

(define (capitalize-first s)
  (if (string-null? s)
      s
      (string-normalize-nfc
       (string-append (string (char-upcase (string-ref s 0))) (substring s 1)))))

(define (final-sigma s)
  "Write a word-final σ as ς."
  (let ((n (string-length s)))
    (if (and (> n 0) (char=? (string-ref s (- n 1)) #\σ))
        (string-append (substring s 0 (- n 1)) "ς")
        s)))

;;; ---------------------------------------------------------------------------
;;; Word diff
;;; ---------------------------------------------------------------------------

(define (lcs-ops a b same?)
  "Edit script turning vector A into vector B along a heaviest common
subsequence. SAME? returns #f (no match), #t (weight 1) or a positive weight,
so better pairings win over merely possible ones. Returns a list of (= i j),
(- i) and (+ j), in order."
  (let* ((n (vector-length a))
         (m (vector-length b))
         (w (+ m 1))
         (t (make-vector (* (+ n 1) w) 0)))
    (define (at i j) (vector-ref t (+ (* i w) j)))
    (define (weight i j)
      (let ((s (same? (vector-ref a i) (vector-ref b j))))
        (cond ((not s) 0) ((eq? s #t) 1) (else s))))
    (do ((i (- n 1) (- i 1))) ((< i 0))
      (do ((j (- m 1) (- j 1))) ((< j 0))
        (let ((s (weight i j)))
          (vector-set! t (+ (* i w) j)
                       (max (at (+ i 1) j) (at i (+ j 1))
                            (if (> s 0) (+ s (at (+ i 1) (+ j 1))) 0))))))
    (let loop ((i 0) (j 0) (acc '()))
      (cond
       ((and (= i n) (= j m)) (reverse acc))
       ((= i n) (loop i (+ j 1) (cons (list '+ j) acc)))
       ((= j m) (loop (+ i 1) j (cons (list '- i) acc)))
       ((let ((s (weight i j))) (and (> s 0) (= (at i j) (+ s (at (+ i 1) (+ j 1))))))
        (loop (+ i 1) (+ j 1) (cons (list '= i j) acc)))
       ((>= (at (+ i 1) j) (at i (+ j 1)))
        (loop (+ i 1) j (cons (list '- i) acc)))
       (else (loop i (+ j 1) (cons (list '+ j) acc)))))))

(define (diff-hunks ops)
  "Group the non-matching runs of OPS into hunks. Each hunk is
(after deleted inserted): AFTER is the index of the last matched base word
before the hunk (-1 at the start), DELETED and INSERTED list the base and other
indexes in the hunk."
  (let loop ((ops ops) (after -1) (dels '()) (ins '()) (acc '()))
    (define (flush)
      (if (and (null? dels) (null? ins))
          acc
          (cons (list after (reverse dels) (reverse ins)) acc)))
    (cond
     ((null? ops) (reverse (flush)))
     ((eq? (caar ops) '=)
      (loop (cdr ops) (cadar ops) '() '()
            (flush)))
     ((eq? (caar ops) '-)
      (loop (cdr ops) after (cons (cadar ops) dels) ins acc))
     (else
      (loop (cdr ops) after dels (cons (cadar ops) ins) acc)))))

;;; ---------------------------------------------------------------------------
;;; Textus Receptus transliteration (Robinson's ASCII scheme)
;;; ---------------------------------------------------------------------------

(define %translit
  '((#\a . #\α) (#\b . #\β) (#\g . #\γ) (#\d . #\δ) (#\e . #\ε) (#\z . #\ζ)
    (#\h . #\η) (#\q . #\θ) (#\i . #\ι) (#\k . #\κ) (#\l . #\λ) (#\m . #\μ)
    (#\n . #\ν) (#\x . #\ξ) (#\o . #\ο) (#\p . #\π) (#\r . #\ρ) (#\s . #\σ)
    (#\v . #\σ) (#\t . #\τ) (#\u . #\υ) (#\f . #\φ) (#\c . #\χ) (#\y . #\ψ)
    (#\w . #\ω)))

(define (translit->greek s)
  "Unaccented lowercase Greek for Robinson's transliteration S, or #f if S
holds a character outside the scheme."
  (let ((chars (map (lambda (c) (assv-ref %translit (char-downcase c)))
                    (string->list s))))
    (and (every identity chars)
         (final-sigma (list->string chars)))))

;;; ---------------------------------------------------------------------------
;;; Files
;;; ---------------------------------------------------------------------------

(define (read-lines path)
  "Lines of PATH with any BOM and carriage returns removed."
  (let* ((text (call-with-input-file path get-string-all))
         (text (if (string-prefix? (string #\xFEFF) text) (substring text 1) text)))
    (remove string-null?
            (string-split (string-delete #\return text) #\newline))))

(define (split-tab line) (string-split line #\tab))

(define (string->tsv-field s)
  (string-map (lambda (c) (if (memv c '(#\tab #\newline)) #\space c)) s))

(define (mkdir-p path)
  (unless (or (string-null? path) (file-exists? path))
    (mkdir-p (dirname path))
    (mkdir path)))

(define (write-if-changed path text check?)
  "Write TEXT to PATH unless it already holds it. Returns 'unchanged, 'wrote, or
'stale (CHECK? set and the file differs)."
  (let ((existing (and (file-exists? path)
                       (call-with-input-file path get-string-all))))
    (cond
     ((and existing (string=? existing text)) 'unchanged)
     (check? 'stale)
     (else
      (mkdir-p (dirname path))
      (call-with-output-file path (lambda (port) (display text port)))
      'wrote))))

;;; ---------------------------------------------------------------------------
;;; Small utilities
;;; ---------------------------------------------------------------------------

(define (hash-inc! table key)
  (hash-set! table key (+ 1 (hash-ref table key 0))))

(define (hash->sorted-alist table less?)
  (sort (hash-map->list cons table) less?))

(define (by-count-then-key a b)
  (or (> (cdr a) (cdr b))
      (and (= (cdr a) (cdr b)) (string<? (format #f "~a" (car a)) (format #f "~a" (car b))))))

(define (most-frequent table)
  (let ((sorted (hash->sorted-alist table by-count-then-key)))
    (and (pair? sorted) (car sorted))))

(define (percent part whole)
  (if (zero? whole) "0.0" (format #f "~,1f" (/ (* 100.0 part) whole))))

(define (tsv-lines header rows)
  (string-append
   (string-join header "\t") "\n"
   (string-concatenate
    (map (lambda (row)
           (string-append (string-join (map (lambda (f) (string->tsv-field (format #f "~a" f))) row) "\t")
                          "\n"))
         rows))))

(define (strong-label n) (if (and n (> n 0) (<= n 5624)) (format #f "G~a" n) ""))

;;; ---------------------------------------------------------------------------
;;; Word rows: the columns of gsb/greek/*.tsv after ref and n
;;; ---------------------------------------------------------------------------

(define (make-word pre word post lemma strong morph flags)
  (list pre word post lemma strong morph flags))
(define word-pre first)
(define word-text second)
(define word-post third)
(define word-lemma fourth)
(define word-strong fifth)
(define word-morph sixth)
(define word-flags seventh)

(define (word-with w . changes)
  "Copy of word W with the named fields replaced."
  (let loop ((w w) (changes changes))
    (match changes
      (() w)
      ((field value . rest)
       (loop (let ((i (assq-ref '((pre . 0) (word . 1) (post . 2) (lemma . 3)
                                  (strong . 4) (morph . 5) (flags . 6))
                                field)))
               (append (take w i) (list value) (drop w (+ i 1))))
             rest)))))

(define (add-flags w flags)
  (word-with w 'flags (delete-duplicates (append (word-flags w) flags))))

(define %word-header '("ref" "n" "pre" "word" "post" "lemma" "strong" "morph" "flags"))

(define (book-table id verses)
  "TSV text for VERSES, a list of ((chapter . verse) . word rows)."
  (tsv-lines %word-header
             (append-map
              (match-lambda
                ((key . words)
                 (map (lambda (w n)
                        (list (format #f "~a.~a.~a" id (car key) (cdr key)) n
                              (word-pre w) (word-text w) (word-post w) (word-lemma w)
                              (strong-label (word-strong w)) (word-morph w)
                              (string-join (word-flags w) ",")))
                      words (iota (length words) 1))))
              verses)))

;;; ---------------------------------------------------------------------------
;;; Spelling choice, shared by decapitalization and TR accent repair
;;; ---------------------------------------------------------------------------

(define (spelling-key s) (string-downcase (grave->acute s)))


(define (capitalized? s)
  (and (> (string-length s) 0) (char-upper-case? (string-ref s 0))))

(define (index-spelling! table key spelling)
  "Count SPELLING (as written, grave made acute) under KEY in TABLE. Words in
unaccented capitals carry no accent information and are skipped."
  (unless (all-caps? spelling)
   (let ((inner (or (hash-ref table key)
                   (let ((h (make-hash-table))) (hash-set! table key h) h))))
    (hash-inc! inner (drop-throwback (grave->acute spelling))))))

(define (drop-throwback s)
  "Remove the extra acute an enclitic throws back onto S (εἶπέν -> εἶπεν)."
  (let* ((d (string-normalize-nfd s))
         (accents (string-count d (lambda (c) (memv c '(#\x0301 #\x0300 #\x0342))))))
    (if (< accents 2)
        s
        (let ((i (string-rindex d #\x0301)))
          (string-normalize-nfc (string-append (substring d 0 i) (substring d (+ i 1))))))))

(define (accent-count s)
  (string-count (string-normalize-nfd s) (lambda (c) (memv c '(#\x0301 #\x0300 #\x0342)))))

(define (strip-acute s)
  (string-normalize-nfc (string-delete #\x0301 (string-normalize-nfd s))))

(define* (unique-spelling table key #:key clitics?)
  "The one spelling recorded under KEY, ignoring case and grave/acute, or #f.
It is capitalized only when every occurrence was. With CLITICS? (use it only
when KEY pins down the word, e.g. letters plus Strong's number) spellings that
differ by an acute alone count as one, and the least accented wins: the acute
on ἔν, μού or εἰμί comes from a following enclitic, not from the word."
  (let ((inner (hash-ref table key)))
    (and inner
         (let* ((forms (hash->sorted-alist inner by-count-then-key))
                (group-of (lambda (f) (let ((s (string-downcase (car f)))) (if clitics? (strip-acute s) s))))
                (groups (delete-duplicates (map group-of forms))))
           (and (= 1 (length groups))
                (let* ((fewest (apply min (map (lambda (f) (accent-count (car f))) forms)))
                       (best (car (filter (lambda (f) (= fewest (accent-count (car f)))) forms))))
                  (if (every (lambda (f) (capitalized? (car f))) forms)
                      (car best)
                      (string-downcase (car best)))))))))

(define (contextual-accent spelling verse-final?)
  "Turn an oxytone's final acute into the grave Greek writes before another word."
  (if verse-final?
      spelling
      (let* ((d (string-normalize-nfd spelling))
             (i (string-rindex d #\x0301)))
        (if (and i (not (string-index d (lambda (c) (memv c (string->list "αεηιουωΑΕΗΙΟΥΩ"))) (+ i 1))))
            (string-normalize-nfc
             (string-append (substring d 0 i) (string #\x0300) (substring d (+ i 1))))
            spelling))))

;;; ---------------------------------------------------------------------------
;;; Lemma lookup from the NT-derived tables
;;; ---------------------------------------------------------------------------

(define (lookup-lemma forms stripped text)
  "Returns (lemma strong flags) for TEXT, or #f. FORMS maps an accented form
(spelling-key) and STRIPPED a fold-key to a hash of (lemma . strong) -> count."
  (define (lemmas-of table) (delete-duplicates (hash-map->list (lambda (k v) (car k)) table)))
  (let ((exact (hash-ref forms (spelling-key text))))
    (if exact
        (let ((best (car (most-frequent exact))))
          (list (car best) (cdr best) (if (> (length (lemmas-of exact)) 1) '("lemma?") '())))
        (let ((loose (hash-ref stripped (fold-key text))))
          (and loose
               (= 1 (length (lemmas-of loose)))
               (let ((best (car (most-frequent loose))))
                 (list (car best) (cdr best) '("lemma?"))))))))

(define (lemmatize forms stripped w)
  (match (lookup-lemma forms stripped (word-text w))
    ((lemma strong flags) (add-flags (word-with w 'lemma lemma 'strong strong) flags))
    (#f w)))

;;; ---------------------------------------------------------------------------
;;; LXX: our Swete transcription (gsb/sources/swete/NN-<id>.tsv)
;;; ---------------------------------------------------------------------------

(define (read-transcription path)
  "Verses of a transcription file: a list of ((chapter . verse) . raw tokens).
Columns: chapter, verse, text; header row first."
  (filter-map (lambda (line)
                (match (split-tab line)
                  ((chapter verse text . _)
                   (let ((tokens (string-tokenize (string-normalize-nfc text))))
                     (and (pair? tokens)
                          (cons (cons (string-trim-both chapter) (string-trim-both verse)) tokens))))
                  (_ (error "expected chapter<TAB>verse<TAB>text in" path line))))
              (cdr (read-lines path))))

(define (siglum? c)
  ;; Editorial sigla such as ⸂ ⸃ ⸆ (U+2E00-U+2E0F).
  (let ((i (char->integer c))) (and (>= i #x2E00) (<= i #x2E0F))))

(define (clean-token tok)
  "Returns (pre word post flags) for a raw token; word is \"\" when the token
holds no Greek (a bare siglum or stray punctuation)."
  (let* ((flags (append (if (string-any siglum? tok) '("siglum") '())
                        (if (string-any (lambda (c) (memv c '(#\[ #\]))) tok) '("bracket") '())))
         (tok (string-filter (lambda (c) (not (or (siglum? c) (memv c '(#\[ #\]))))) tok))
         (parts (split-punct tok)))
    (list (first parts) (normalize-elision (second parts)) (third parts) flags)))

(define (lxx-verse-words tokens)
  "Word rows for one verse's raw tokens. Tokens without Greek are dropped; their
flags and punctuation go to the previous word (or the next, at verse start)."
  (let loop ((tokens (map clean-token tokens)) (pending '()) (acc '()))
    (match tokens
      (() (reverse (if (and (pair? acc) (pair? pending))
                       (cons (add-flags (car acc) pending) (cdr acc))
                       acc)))
      (((pre word post flags) . rest)
       (cond
        ((not (string-null? word))
         (loop rest '() (cons (make-word pre word post "" #f "" (append pending flags)) acc)))
        ((pair? acc)
         (loop rest '() (cons (add-flags (word-with (car acc) 'post (string-append (word-post (car acc)) pre post))
                                         (append pending flags))
                              (cdr acc))))
        (else (loop rest (append pending flags) acc)))))))

(define (decapitalize verses spellings)
  "Restore Swete's capitalized chapter openings where the word has exactly one
known accented spelling. SPELLINGS (fold-key -> spellings, see index-spelling!)
comes pre-seeded with other corpora; the non-capital words of VERSES are added.
Returns (values verses report-rows), each report row (key n capitals status
restored)."
  (for-each (match-lambda
              ((key . words)
               (for-each (lambda (w) (unless (all-caps? (word-text w))
                                       (index-spelling! spellings (fold-key (word-text w)) (word-text w))))
                         words)))
            verses)
  (let* ((report '())
         (result
          (map (match-lambda
                 ((key . words)
                  (let ((last (- (length words) 1)))
                    (cons key
                          (map (lambda (w n)
                                 (if (not (all-caps? (word-text w)))
                                     w
                                     (let ((found (unique-spelling spellings (fold-key (word-text w)))))
                                       (set! report (cons (list key (+ n 1) (word-text w)
                                                                (if found "restored" "unresolved")
                                                                (or found ""))
                                                          report))
                                       (if found
                                           (add-flags (word-with w 'word
                                                                 (let ((s (contextual-accent found (= n last))))
                                                                   (if (zero? n) (capitalize-first s) s)))
                                                      '("decap"))
                                           (add-flags w '("caps"))))))
                               words (iota (length words)))))))
               verses)))
    (values result (reverse report))))
