;; Copyright (C) 2026
;;
;; The pure parts of the Swete transcription method (see
;; .claude/skills/gsb-transcribe/SKILL.md): reading page files, building verse
;; tables in the common numbering, validating a book, cutting the main text out
;; of hOCR, and collating OCR readings against our own reading. No I/O here
;; beyond what callers pass in; scripts/gsb-swete.scm does the files and ffmpeg.

(define-module (scripts lib swete)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-13)
  #:use-module ((scripts lib gsb) #:select (lcs-ops diff-hunks))
  #:export (parse-page
            page-header
            page-lines
            line-items
            book-verses
            book-problems
            greek-char?
            hocr-lines
            main-text-lines
            suggest-box
            ocr-normalize
            page-tokens
            ocr-tokens
            collate
            class-basis
            reconcile
            indent-hints
            todo?
            replace-all))

;;; ---------------------------------------------------------------------------
;;; Small helpers
;;; ---------------------------------------------------------------------------

(define (replace-all s from to)
  (let loop ((start 0) (acc '()))
    (match (string-contains s from start)
      (#f (string-concatenate-reverse acc (substring s start)))
      (i (loop (+ i (string-length from)) (cons* to (substring s start i) acc))))))

(define (squeeze s) (string-join (string-tokenize s) " "))

(define (greek-char? c)
  (let ((i (char->integer c)))
    (or (<= #x370 i #x3FF) (<= #x1F00 i #x1FFF))))

(define (combining? c) (eq? (char-general-category c) 'Mn))

(define (base-letters s)
  "S without diacritics, lowercased, final sigma folded."
  (string-map (lambda (c) (if (char=? c #\ς) #\σ c))
              (string-downcase (string-filter (negate combining?) (string-normalize-nfd s)))))

;;; ---------------------------------------------------------------------------
;;; Page files
;;; ---------------------------------------------------------------------------
;;
;; A page file is `# key ...` header/comment lines and one printed line per text
;; line. Markers: {C3} Swete's chapter 3, {7} Swete's verse 7, {=2:25} the
;; common reference from here on (Swete's marginal parenthesized number), {P}
;; a new paragraph, {S} a line of poetry (a stich printed on its own indented line). ¶ and § are witness marks kept as printed.

(define %marker (make-regexp "\\{([^}]*)\\}"))
(define %scan-rx (make-regexp "^# *([a-z0-9]+) leaf ([0-9]+)( \\(printed page ([^)]*)\\))?"))

(define (parse-page text)
  "Returns (header lines): HEADER an alist of `# key value...` comment lines
(key: \"scan\", \"box\", \"done\", ...), LINES a list of (n . text) for the
printed lines, n counting from 1."
  (let loop ((ls (string-split text #\newline)) (n 1) (header '()) (lines '()))
    (match ls
      (() (list (reverse header) (reverse lines)))
      ((l . rest)
       (let ((t (string-trim-right l)))
         (cond
          ((string-null? (string-trim t)) (loop rest n header lines))
          ((string-prefix? "#" t)
           (let ((m (regexp-exec %scan-rx t))
                 (words (string-tokenize (string-drop t 1))))
             (loop rest n
                   (cond (m (acons "scan" (list (match:substring m 1) (string->number (match:substring m 2)) (match:substring m 4)) header))
                         ((pair? words) (acons (car words) (cdr words) header))
                         (else header))
                   lines)))
          (else (loop rest (+ n 1) header (cons (cons n t) lines)))))))))

(define (page-header page key) (assoc-ref (first page) key))
(define (page-lines page) (second page))

(define (parse-marker s)
  "'(chapter n), '(verse n), '(verse n skip) for {52!} (Swete's own numbering
skips to 52 here, as printed), '(common c v part) with PART \"\" or a half-verse
letter (\"a\" for {=31:48a}), '(para), '(stich) or #f."
  (cond
   ((string-match "^C([0-9]+)$" s) => (lambda (m) (list 'chapter (string->number (match:substring m 1)))))
   ((string-match "^([0-9]+)$" s) => (lambda (m) (list 'verse (string->number (match:substring m 1)))))
   ((string-match "^([0-9]+)!$" s) => (lambda (m) (list 'verse (string->number (match:substring m 1)) 'skip)))
   ((string-match "^=([0-9]+):([0-9]+)([a-z]?)$" s)
    => (lambda (m) (list 'common (string->number (match:substring m 1)) (string->number (match:substring m 2))
                         (match:substring m 3))))
   ((string=? s "P") '(para))
   ((string=? s "S") '(stich))
   (else #f)))

(define (line-items line)
  "Split a printed line into strings and markers ('(chapter n) etc.; an unknown
marker is '(bad \"text\"))."
  (let loop ((start 0) (acc '()))
    (match (regexp-exec %marker line start)
      (#f (reverse (cons (substring line start) acc)))
      (m (loop (match:end m)
               (cons (or (parse-marker (match:substring m 1)) (list 'bad (match:substring m 0)))
                     (cons (substring line start (match:start m)) acc)))))))

(define (strip-sigla s) (string-delete (lambda (c) (memv c '(#\¶ #\§))) s))

;;; ---------------------------------------------------------------------------
;;; Verse tables
;;; ---------------------------------------------------------------------------

(define (book-events pages)
  "PAGES: list of (leaf . page) in reading order. Returns a flat list of events:
(line leaf n), (text s), (chapter n), (verse n), (common c v), (para), (bad s),
(hyphen) after a line ending in '-'."
  (append-map
   (match-lambda
     ((leaf . page)
      (append-map
       (match-lambda
         ((n . line)
          (let ((clean (string-trim-right (strip-sigla line))))
            (append (list (list 'line leaf n))
                    (map (lambda (it) (if (string? it) (list 'text it) it)) (line-items line))
                    (if (string-suffix? "-" clean) '((hyphen)) '())))))
       (page-lines page))))
   pages))

(define (ref-key ref)
  "(chapter verse) of a reference (c v part . flags): VERSE is a number, or a
string like \"48a\" for a half verse."
  (match ref ((c v "" . _) (list c v)) ((c v part . _) (list c (string-append (number->string v) part)))))

(define (book-verses pages)
  "Rows (chapter verse text) in the common numbering, from PAGES ((leaf . page)
in order). Swete's own verse {N} sets the reference to his chapter:N; {=c:v}
(or {=c:va}, a half verse) overrides it until his next verse marker.
Consecutive text under one reference is one row; rows stay in printed order,
so a transposed verse comes out of numerical order. VERSE is a number, or a
string like \"48a\". Hyphenated line ends are joined; ¶ § and markers are
dropped. Returns (values rows problems), problems as for book-problems."
  (let loop ((evs (book-events pages)) (ch #f) (ref #f) (text "") (join? #f)
             (where #f) (rows '()) (problems '()))
    (define (flush)
      (let ((t (squeeze text)) (key (and ref (ref-key ref))))
        (cond ((string-null? t) rows)
              ((and (pair? rows) (equal? (take (car rows) 2) key))
               (cons (append key (list (string-append (third (car rows)) " " t))) (cdr rows)))
              (else (cons (append key (list t)) rows)))))
    (match evs
      (() (values (reverse (map (lambda (r) (list (first r) (second r) (string-normalize-nfc (third r)))) (flush)))
                  (reverse problems)))
      ((ev . rest)
       (match ev
         (('line leaf n) (loop rest ch ref text join? (list leaf n) rows problems))
         (('hyphen) (loop rest ch ref text #t where rows problems))
         (('text s)
          (let ((s (squeeze (strip-sigla s))))
            (cond
             ((string-null? s) (loop rest ch ref text join? where rows problems))
             ((not ref)
              (loop rest ch ref text #f where rows
                    (cons (list (first where) (second where) 'fail
                                (format #f "text before any verse marker: ~s (a page that starts mid-verse needs the page before it)" s))
                          problems)))
             (else
              (loop rest ch ref
                    (cond ((string-null? text) s)
                          (join? (string-append (string-drop-right (string-trim-right text) 1) s))
                          (else (string-append text " " s)))
                    #f where rows problems)))))
         (('chapter n) (loop rest n ref text join? where rows problems))
         (('verse n . _)
          (if ch
              (loop rest ch (list ch n "") "" #f where (flush) problems)
              (loop rest ch ref text join? where rows
                    (cons (list (first where) (second where) 'fail (format #f "verse {~a} before any {C<n>} chapter marker" n)) problems))))
         (('common c v part) (loop rest ch (list c v part) "" #f where (flush) problems))
         (_ (loop rest ch ref text join? where rows problems)))))))

;;; ---------------------------------------------------------------------------
;;; Validation
;;; ---------------------------------------------------------------------------

(define %allowed-punct (string->char-set ".,·;:᾽()[]¶§-' "))

(define (bad-chars s)
  "Characters of S that are neither Greek letters/diacritics nor allowed punctuation."
  (delete-duplicates
   (filter (lambda (c) (not (or (char-set-contains? %allowed-punct c)
                                (and (greek-char? c) (not (memv c '(#\; #\·))))
                                (combining? c))))
           (string->list s))))

(define (ref<? a b) (or (< (first a) (first b)) (and (= (first a) (first b)) (< (second a) (second b)))))

(define (book-problems pages first-leaf last-leaf step)
  "Problems in PAGES ((leaf . page), in order) as (leaf line severity message),
severity 'fail or 'warn. Sequence checks restart after a gap in the leaves.
FIRST-LEAF / LAST-LEAF (or #f) say whether the book's opening and end are present."
  (define (line-problems leaf page)
    (append-map
     (match-lambda
       ((n . line)
        (let ((text (regexp-substitute/global #f %marker line 'pre 'post)))
          (append
           (if (string=? line (string-normalize-nfc line)) '()
               (list (list leaf n 'fail "not NFC: rewrite the line in composed (NFC) form")))
           (match (bad-chars text)
             (() '())
             (cs (list (list leaf n 'fail
                             (format #f "non-Greek character~a ~a: read the image again (Latin look-alikes, stray digits?)"
                                     (if (> (length cs) 1) "s" "")
                                     (string-join (map (lambda (c) (format #f "~a (U+~a)" c (string-upcase (number->string (char->integer c) 16)))) cs) ", "))))))
           (filter-map (match-lambda (('bad s) (list leaf n 'fail (format #f "unknown marker ~a (use {C3} {7} {7!} {=2:25} {=31:48a} {P} {S})" s)))
                                     (_ #f))
                       (line-items line))))))
     (page-lines page)))
  (define (header-problems leaf page)
    (append
     (match (page-header page "scan")
       ((scan l . _) (if (= l leaf) '() (list (list leaf 0 'fail (format #f "header says leaf ~a but the file is leaf ~a" l leaf)))))
       (_ (list (list leaf 0 'fail "missing the first header line `# <scan> leaf NNNN (printed page P)`"))))
     (match (page-header page "box")
       (((? string->number) (? string->number) (? string->number) (? string->number)) '())
       (_ (list (list leaf 0 'fail "missing `# box Y0 Y1 X0 X1`: run ./scripts/gsb-swete.sh box"))))
     (if (null? (page-lines page)) (list (list leaf 0 'fail "no text lines")) '())))
  ;; Sequence checks over the events of one run of consecutive leaves.
  (define (run-problems run)
    (let* ((opens? (and first-leaf (= (car (first run)) first-leaf)))
           (ends? (and last-leaf (= (car (last run)) last-leaf)))
           ;; (c v) -> ((part leaf line) ...): common references that have text
           (seen (make-hash-table)))
      (define (ref-text ref) (apply format #f "~a:~a" (ref-key ref)))
      (define (duplicate ref where)
        ;; A message if REF starts a second row for the same common verse (or
        ;; mixes a whole verse with its halves), else #f; records REF.
        (match ref
          ((c v part . _)
           (let* ((before (hash-ref seen (list c v) '()))
                  (clash (find (lambda (p) (or (string=? (car p) part) (string-null? (car p)) (string-null? part))) before)))
             (hash-set! seen (list c v) (cons (cons part where) before))
             (and clash
                  (format #f "common reference ~a again (already at leaf ~a line ~a): each common verse or half verse is given once per book; a {=c:v} marker is wrong, or the halves need letters ({=~a:~aa} ... {=~a:~ab})"
                          (ref-text ref) (second clash) (third clash) c v c v))))))
      (let loop ((evs (book-events run)) (where '(0 0)) (ch #f) (v #f) (ref #f) (last-ref #f)
                 (pending-text? #f) (depth (if opens? 0 #f)) (hyphen? #f) (acc '()))
        (define (add sev fmt . args) (cons (list (first where) (second where) sev (apply format #f fmt args)) acc))
        (match evs
          (()
           (reverse
            (append (if (and ends? depth (> depth 0)) (list (list (first where) (second where) 'fail "a [ is never closed")) '())
                    (if (and ends? hyphen?) (list (list (first where) (second where) 'fail "book ends in a hyphen")) '())
                    acc)))
          ((ev . rest)
           (match ev
             (('line leaf n) (loop rest (list leaf n) ch v ref last-ref pending-text? depth #f acc))
             (('hyphen) (loop rest where ch v ref last-ref pending-text? depth #t acc))
             (('chapter n)
              (loop rest where n 'after-chapter ref last-ref pending-text? depth hyphen?
                    (if (and ch (not (= n (+ ch 1)))) (add 'fail "Swete chapter {C~a} after chapter ~a" n ch)
                        (if (and (not ch) opens? (not (= n 1))) (add 'fail "book opens with {C~a}, expected {C1}" n) acc))))
             (('verse n . skip)
              ;; V is the last Swete verse, 'after-chapter right after {C},
              ;; #f at the start of a run (unknown). Swete's own numbers must
              ;; run on by one, unless the page marks a printed skip {52!}.
              (loop rest where ch n (and ch (list ch n "")) last-ref pending-text? depth hyphen?
                    (cond ((eq? v 'after-chapter)
                           (if (= n 1) acc (add 'fail "Swete chapter ~a starts with verse {~a}, expected {1}" ch n)))
                          ((and (number? v) (pair? skip) (<= n (+ v 1)))
                           (add 'fail "{~a!} marks a skip in Swete's numbers, but it follows {~a}: write {~a}" n v n))
                          ((and (number? v) (null? skip) (not (= n (+ v 1))))
                           (add 'fail "Swete verse {~a} after {~a}: misread number or missing marker (if Swete really prints no ~a, write {~a!})"
                                n v (+ v 1) n))
                          (else acc))))
             (('common c vv part) (loop rest where ch v (list c vv part 'explicit) last-ref pending-text? depth hyphen? acc))
             (('text s)
              (let* ((s (squeeze (strip-sigla s)))
                     (brackets (filter (lambda (c) (memv c '(#\[ #\]))) (string->list s))))
                (if (string-null? s)
                    (loop rest where ch v ref last-ref pending-text? depth hyphen? acc)
                    (let*-values
                        (((acc2) (cond ((or (not ref) (and last-ref (equal? (take ref 3) (take last-ref 3)))) acc)
                                       ((duplicate ref where) => (lambda (msg) (add 'fail "~a" msg)))
                                       ;; An explicit {=c:v} may go anywhere (the LXX
                                       ;; transposes verses); only the references
                                       ;; that follow Swete's own numbers are judged,
                                       ;; against the one before when that did too.
                                       ((or (memq 'explicit ref) (and last-ref (memq 'explicit last-ref))) acc)
                                       ((and last-ref (not (ref<? last-ref ref)))
                                        (add 'warn "common reference ~a comes after ~a: a {=c:v} marker is wrong or missing?"
                                             (ref-text ref) (ref-text last-ref)))
                                       ((and last-ref (= (first ref) (first last-ref)) (> (second ref) (+ 1 (second last-ref))))
                                        (add 'warn "common reference jumps from ~a:~a to ~a:~a: check the margin for a parenthesized number"
                                             (first last-ref) (second last-ref) (first ref) (second ref)))
                                       ((and last-ref (> (first ref) (first last-ref)) (not (= (second ref) 1)))
                                        (add 'warn "common chapter ~a starts at verse ~a: check the margin for a parenthesized number"
                                             (first ref) (second ref)))
                                       (else acc)))
                         ((depth acc3)
                          (let bl ((bs brackets) (d depth) (a acc2))
                            (match bs
                              (() (values d a))
                              ((#\[ . more)
                               (if (and d (> d 0))
                                   (bl more (+ d 1) (cons (list (first where) (second where) 'fail "[ inside [ ]: brackets do not nest in Swete") a))
                                   (bl more 1 a)))
                              ((#\] . more)
                               (cond ((not d) (bl more 0 a))  ; opened on a page before this run
                                     ((= d 0) (bl more 0 (cons (list (first where) (second where) 'fail "] without an opening [") a)))
                                     (else (bl more (- d 1) a))))))))
                      (loop rest where ch v ref (or ref last-ref) #t depth hyphen? acc3)))))
             (_ (loop rest where ch v ref last-ref pending-text? depth hyphen? acc))))))))
  (define (runs pages)
    ;; Split into runs of consecutive leaves (leaf, leaf+step, ...).
    (fold-right (lambda (p acc)
                  (match acc
                    (((q . more) . others) (if (= (+ (car p) step) (car q))
                                               (cons (cons p (cons q more)) others)
                                               (cons (list p) acc)))
                    (() (list (list p)))))
                '() pages))
  (sort
   (append
    (append-map (match-lambda ((leaf . page) (append (header-problems leaf page) (line-problems leaf page)))) pages)
    (append-map run-problems (runs pages))
    ;; Text before the first marker is only an error when the book's opening is here.
    (if (and (pair? pages) first-leaf (= (car (first pages)) first-leaf))
        (call-with-values (lambda () (book-verses pages)) (lambda (rows problems) problems))
        '()))
   (lambda (a b) (or (< (first a) (first b)) (and (= (first a) (first b)) (< (second a) (second b)))))))

;;; ---------------------------------------------------------------------------
;;; hOCR
;;; ---------------------------------------------------------------------------
;; A word is (x0 y0 x1 y1 text); a line is (y0 y1 words).

(define %line-rx (make-regexp "class=['\"]ocr_(line|textfloat|header|caption)['\"][^>]*title=['\"]bbox ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)"))
(define %word-rx (make-regexp "class=['\"]ocrx_word['\"][^>]*title=['\"]bbox ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)[^>]*>"))
(define %tag-rx (make-regexp "<[^>]*>"))

(define (unescape s)
  (fold (lambda (p s) (replace-all s (car p) (cdr p))) s
        '(("&lt;" . "<") ("&gt;" . ">") ("&quot;" . "\"") ("&#39;" . "'") ("&apos;" . "'") ("&amp;" . "&"))))

(define (num m i) (string->number (match:substring m i)))

(define (hocr-words chunk)
  (filter-map
   (lambda (m)
     (let* ((end (or (string-contains chunk "</span>" (match:end m)) (string-length chunk)))
            (text (string-trim-both
                   (unescape (regexp-substitute/global #f %tag-rx (substring chunk (match:end m) end) 'pre 'post)))))
       (and (not (string-null? text))
            (list (num m 1) (num m 2) (num m 3) (num m 4) text))))
   (list-matches %word-rx chunk)))

(define (hocr-lines str)
  "The text lines of a one-page hOCR document."
  (let* ((ms (list-matches %line-rx str))
         (ends (append (map match:start (if (pair? ms) (cdr ms) '())) (list (string-length str)))))
    (filter-map (lambda (m end)
                  (let ((words (hocr-words (substring str (match:end m) end))))
                    (and (pair? words) (list (num m 3) (num m 5) words))))
                ms ends)))

(define (wx0 w) (first w)) (define (wy0 w) (second w)) (define (wx1 w) (third w)) (define (wy1 w) (fourth w))
(define (wtext w) (fifth w))

(define (line-text l) (string-join (map wtext (third l)) " "))
(define (greek-count s) (count greek-char? (string->list s)))

(define (greek-line? text)
  "Enough Greek to be text rather than accent-row junk or Latin apparatus."
  (let* ((cs (string->list text))
         (g (count greek-char? cs)))
    (and (>= g 5)
         (>= g (* 3/4 (max 1 (count char-alphabetic? cs))))
         (>= g (* 3/5 (count (negate char-whitespace?) cs))))))

(define (main-text-lines lines box)
  "The main-text lines of hOCR LINES inside BOX (y0 y1 x0 x1), top to bottom:
words whose left edge is in [x0, x1) and whose middle is in [y0, y1], lines with
too little Greek dropped, lines that overlap vertically by more than half the shorter one's height merged
(the Greek-richer line's words win, the other's fill horizontal gaps)."
  (match box
    ((Y0 Y1 X0 X1)
     (let* ((inside? (lambda (w) (and (<= X0 (wx0 w)) (< (wx0 w) X1)
                                      (<= Y0 (/ (+ (wy0 w) (wy1 w)) 2) Y1))))
            (kept (filter-map
                   (lambda (l)
                     (let ((ws (filter inside? (third l))))
                       (and (pair? ws)
                            (greek-line? (string-join (map wtext ws) " "))
                            (list (apply min (map wy0 ws)) (apply max (map wy1 ws)) ws))))
                   lines))
            (mid (lambda (l) (+ (first l) (second l))))
            (sorted (sort kept (lambda (a b) (< (mid a) (mid b))))))
       (define (merge l acc)
         (match acc
           ((prev . more)
            (if (> (- (min (second l) (second prev)) (max (first l) (first prev)))
                   (/ (min (- (second l) (first l)) (- (second prev) (first prev))) 2))
                (let* ((rich (if (>= (greek-count (line-text prev)) (greek-count (line-text l))) prev l))
                       (poor (if (eq? rich prev) l prev))
                       (fill (filter (lambda (w) (every (lambda (v) (or (<= (wx1 w) (wx0 v)) (>= (wx0 w) (wx1 v))))
                                                        (third rich)))
                                     (third poor))))
                  (cons (list (first rich) (second rich) (append (third rich) fill)) more))
                (cons l acc)))
           (() (list l))))
       (map (lambda (l) (list (first l) (second l) (sort (third l) (lambda (a b) (< (wx0 a) (wx0 b))))))
            (reverse (fold merge '() sorted)))))))

(define (percentile xs p)
  (let ((v (list->vector (sort xs <))))
    (vector-ref v (min (- (vector-length v) 1) (inexact->exact (floor (* p (vector-length v))))))))

(define (suggest-box lines width height)
  "A first guess at the main-text box (y0 y1 x0 x1) from all hOCR LINES of a
page. The core is the Greek lines of five or more words, mostly accented
(Swete prints the apparatus unaccented) and without the apparatus's lemma
brackets, from the first such line to the end of the longest run of them. It
then grows line by line to neighbors at the normal line spacing (the running
head and the apparatus are set off by a wider gap) that are at least 40%
accented, which brings in short or badly read first and last lines. Left and
right edges come from words of three or more Greek letters (not margin
numbers or sigla), a little loose on the left: a sliver of margin hurts the
OCR less than a clipped first letter. Tuned against the 98 hand-set boxes of
Genesis leaves 38-135 (see the bead ursinia-vff.13). Known misses: a last line
after a paragraph gap, and the right edge of an all-poetry page (Gen 49),
which follows the typical line. Always check it by eye."
  (let* ((accented? (lambda (w) (string-any combining? (string-normalize-nfd (wtext w)))))
         (greek-words (lambda (l) (filter (lambda (w) (>= (greek-count (wtext w)) 2)) (third l))))
         (apparatus? (lambda (l) (>= (string-count (line-text l) #\]) 2)))
         (caps? (lambda (l) (every (lambda (w) (not (string-any char-lower-case? (wtext w)))) (greek-words l))))
         (all (main-text-lines lines (list 0 height 0 width)))
         (good (filter (lambda (l) (and (>= (length (third l)) 5)
                                        (greek-line? (line-text l))
                                        (>= (count accented? (third l)) (* 3/4 (length (third l))))
                                        (not (apparatus? l))))
                       all)))
    (and (>= (length good) 2)
         (let* ((pitch (percentile (map (lambda (a b) (- (first b) (first a))) (drop-right good 1) (cdr good)) 0.5))
                ;; Runs of good lines no more than six lines apart. The core runs
                ;; from the first good line to the end of the longest run: only the
                ;; apparatus lies below the text, and an apparatus line that OCR
                ;; happens to accent is cut off by the gap before it.
                (runs (fold-right (lambda (l acc)
                                    (if (and (pair? acc) (< (- (first (caar acc)) (first l)) (* 6 pitch)))
                                        (cons (cons l (car acc)) (cdr acc))
                                        (cons (list l) acc)))
                                  '() good))
                (longest (fold (lambda (r best) (if (> (length r) (length best)) r best)) (car runs) runs))
                (core (append-map identity (take runs (+ 1 (list-index (lambda (r) (eq? r longest)) runs)))))
                ;; A neighbor at normal spacing that is at least 40% accented
                ;; (a garbled main-text line still is; the apparatus is not).
                (text? (lambda (l) (and (pair? (greek-words l)) (greek-line? (line-text l))
                                        (not (apparatus? l)) (not (caps? l))
                                        (>= (count accented? (third l)) (* 2/5 (length (third l)))))))
                (near (* 0.45 pitch)))
           (let grow ((top (apply min (map first core))) (bot (apply max (map second core))))
             (let ((above (find (lambda (l) (and (< (second l) top) (< (- top (second l)) near) (text? l))) all))
                   (below (find (lambda (l) (and (> (first l) bot) (< (- (first l) bot) near) (text? l))) all)))
               (if (or above below)
                   (grow (if above (first above) top) (if below (second below) bot))
                   (let ((edges (filter-map (lambda (l)
                                              (let ((ws (filter (lambda (w) (>= (greek-count (wtext w)) 3)) (third l))))
                                                (and (pair? ws) (>= (first l) top) (<= (second l) bot)
                                                     (cons (apply min (map wx0 ws)) (apply max (map wx1 ws))))))
                                            all)))
                     (list (max 0 (- top 25))
                           (min height (+ bot 25))
                           (max 0 (- (percentile (map car edges) 0.1) 25))
                           (min width (+ (percentile (map cdr edges) 0.9) 20)))))))))))

;;; ---------------------------------------------------------------------------
;;; Indentation hints
;;; ---------------------------------------------------------------------------

(define (indent-hints lines page)
  "Notes on lines the scan indents (a paragraph) without {P}, or {P} lines it
does not indent, from OCR main-text LINES, when their count matches PAGE's.
A line's left edge is its first word with Greek letters (not a margin number
caught in the box); the flush edge is the lower quartile of those, so one stray
word cannot move it. A line whose OCR first word is not our first word (both
OCRs dropped it) is not judged. {S} lines are not required to look indented: a
page of poetry has no flush lines to compare with."
  (let ((plines (page-lines page)))
    (if (or (null? lines) (not (= (length lines) (length plines))))
        '()
        (let* ((first-word (lambda (l) (or (find (lambda (w) (>= (greek-count (wtext w)) 2)) (third l)) (car (third l)))))
               (x0s (map (lambda (l) (wx0 (first-word l))) lines))
               (left (percentile x0s 0.25))
               (em (* 1.4 (percentile (map (lambda (l) (- (second l) (first l))) lines) 0.5)))
               (letters (lambda (s) (string-filter char-alphabetic? (base-letters s))))
               (ours (lambda (n) (match (filter (lambda (t) (= (second t) n)) (page-tokens page))
                                   (((t . _) . _) t)
                                   (() #f))))
               (same-start? (lambda (l n)
                              (let ((o (letters (wtext (first-word l)))) (c (and=> (ours n) letters)))
                                (and c (not (string-null? c)) (not (string-null? o))
                                     (or (string-suffix? c o) (string-suffix? o c)))))))
          (filter-map
           (lambda (x l pl)
             (let ((indented? (> (- x left) em))
                   (para? (string-contains (cdr pl) "{P}"))
                   (stich? (string-contains (cdr pl) "{S}")))
               (cond ((and indented? (not (or para? stich?)) (> (car pl) 1) (same-start? l (car pl))
                           ;; a superscript verse number at the line start pushes the word right
                           (not (string-match "^\\{[0-9]+!?\\}" (cdr pl))))
                      (format #f "line ~a looks indented in the scan: a new paragraph? (add {P} at its start, or {S} for a line of poetry)" (car pl)))
                     ((and para? (not indented?))
                      (format #f "line ~a has {P} but does not look indented: check the image" (car pl)))
                     (else #f))))
           x0s lines plines)))))

;;; ---------------------------------------------------------------------------
;;; Collation
;;; ---------------------------------------------------------------------------

(define %breathing
  ;; Spacing breathings/accents OCR writes before a capital, as combining marks.
  '((#\᾿ . "̓") (#\’ . "̓") (#\' . "̓") (#\῾ . "̔") (#\‘ . "̔")
    (#\῎ . "̓́") (#\῍ . "̓̀") (#\῏ . "̓͂")
    (#\῞ . "̔́") (#\῝ . "̔̀") (#\῟ . "̔͂")))

(define (ocr-normalize s)
  "NFC, with a spacing breathing before a capital put on the capital (᾿Α -> Ἀ)
and an apostrophe-like mark ending a word made the elision mark ᾽."
  (let loop ((cs (string->list (string-normalize-nfd s))) (acc '()))
    (match cs
      (() (let ((t (string-normalize-nfc (list->string (reverse acc)))))
            (if (and (> (string-length t) 1) (memv (string-ref t (- (string-length t) 1)) '(#\’ #\' #\᾿)))
                (string-append (string-drop-right t 1) "᾽")
                t)))
      ((c next . rest)
       (=> fail)
       (let ((marks (assv-ref %breathing c)))
         (if (and marks (greek-char? next) (char-upper-case? next))
             (loop rest (append (reverse (string->list marks)) (list next) acc))
             (fail))))
      ((c . rest) (loop rest (cons c acc))))))

(define (page-tokens page)
  "Our reading as tokens (text line at-verse?): markers and ¶ § removed;
AT-VERSE? when a verse marker stands right before the token."
  (append-map
   (match-lambda
     ((n . line)
      (let loop ((items (line-items line)) (at-verse? #f) (acc '()))
        (match items
          (() (reverse acc))
          (((? string? s) . rest)
           (let ((toks (string-tokenize (string-normalize-nfc (strip-sigla s)))))
             (loop rest #f
                   (append (reverse (map (lambda (t i) (list t n (and at-verse? (= i 0)
                                                                     (not (char-whitespace? (string-ref (strip-sigla s) 0))))))
                                         toks (iota (length toks))))
                           acc))))
          ((('verse . _) . rest) (loop rest #t acc))
          ((('chapter _) . rest) (loop rest #t acc))
          ((_ . rest) (loop rest at-verse? acc))))))
   (page-lines page)))

(define (ocr-tokens lines)
  "OCR main-text LINES as tokens (text word line-index). A lone `;` joins the
word before it on its line: Swete sets a thin space before the question mark,
which OCR reads as a word break."
  (append-map (lambda (l k)
                (reverse
                 (fold (lambda (t acc)
                         (if (and (string=? (first t) ";") (pair? acc) (string-any greek-char? (string-take-right (first (car acc)) 1)))
                             (cons (cons (string-append (first (car acc)) ";") (cdr (car acc))) (cdr acc))
                             (cons t acc)))
                       '()
                       (append-map (lambda (w) (map (lambda (t) (list (ocr-normalize t) w k))
                                                    (string-tokenize (wtext w))))
                                   (third l)))))
              lines (iota (length lines))))

(define (align c o)
  "Map each token of C (vector of strings) to the tokens of O it reads as:
a vector of (main . extra), lists of indexes into O. MAIN replaces the token,
EXTRA was inserted after it."
  (let ((m (make-vector (vector-length c) '(() . ()))))
    (for-each
     (match-lambda
       (('= i j) (vector-set! m i (list (list j))))
       (_ #f))
     (lcs-ops c o string=?))
    (for-each
     (match-lambda
       ((after () ins)
        (when (>= after 0)
          (let ((e (vector-ref m after)))
            (vector-set! m after (cons (car e) (append (cdr e) ins))))))
       ((after dels ins)
        (let ((n (length dels)))
          (for-each (lambda (i k)
                      (vector-set! m i (cond ((>= k (length ins)) (list '()))
                                             ((< k (- n 1)) (list (list (list-ref ins k))))
                                             ;; the last one takes the rest as extras
                                             (else (cons (list (list-ref ins k)) (drop ins (+ k 1)))))))
                    dels (iota n)))))
     (diff-hunks (lcs-ops c o string=?)))
    m))

(define (reading o-texts entry)
  "Display string of an alignment ENTRY: words, `∅` when none, ` +x` for extras."
  (let ((main (map (lambda (j) (vector-ref o-texts j)) (car entry)))
        (extra (map (lambda (j) (vector-ref o-texts j)) (cdr entry))))
    (string-append (if (null? main) "∅" (string-join main " "))
                   (if (null? extra) "" (string-append " +" (string-join extra " "))))))

(define (strip-brackets s) (string-delete (lambda (c) (memv c '(#\[ #\] #\space))) s))
(define %ano-glyphs '(#\" #\: #\᾽ #\' #\’ #\- #\· #\.))

(define (marks-of s)
  "Per base letter, the list of combining marks (NFD)."
  (reverse
   (fold (lambda (c acc)
           (if (and (combining? c) (pair? acc))
               (cons (cons (caar acc) (cons c (cdar acc))) (cdr acc))
               (cons (list c) acc)))
         '() (string->list (string-normalize-nfd s)))))

(define (classify c main extras at-verse?)
  "Class of one OCR reading MAIN (string, or #f when OCR has nothing) against
our token C (EXTRAS: OCR words after it that match nothing of ours): same,
R0-R5 (known OCR failures), DROP (OCR lacks some of our
diacritics, letters equal), DIA (diacritics differ), OPEN (letters differ)."
  (define (ano-fix s)   ; R2: OCR's glyph for the ano teleia; a dropped elision mark
    (cond ((and (string-suffix? "·" c) (> (string-length s) 0)
                (memv (string-ref s (- (string-length s) 1)) %ano-glyphs))
           (string-append (string-drop-right s 1) "·"))
          ((and (string-suffix? "᾽" c) (string=? s (string-drop-right c 1))) c)
          (else s)))
  (cond
   ((not main) 'R0)
   ((string=? main c) (if (pair? extras) 'R3 'same))
   ((and (string-any (lambda (ch) (memv ch '(#\[ #\]))) c)
         (string=? (strip-brackets (string-concatenate (cons main extras))) (strip-brackets c))) 'R4)
   ((string=? (ano-fix main) c) 'R2)
   ((and at-verse? (string-suffix? c (ano-fix main))
         (<= (- (string-length main) (string-length c)) 3)) 'R1)
   ((string-any (lambda (ch) (or (char<=? #\a ch #\z) (char<=? #\A ch #\Z))) main) 'R5)
   ((string=? (base-letters main) (base-letters c))
    (let ((mo (marks-of main)) (mc (marks-of c)))
      (if (and (= (length mo) (length mc))
               (every (lambda (a b) (lset<= eqv? (cdr a) (cdr b))) mo mc))
          'DROP 'DIA)))
   (else 'OPEN)))

(define %known '(same R0 R1 R2 R3 R4 R5))

(define (class-basis ca cb)
  "Decision basis for an automatically settled row, or #f if it needs a zoom."
  (define (desc k)
    (assq-ref '((R0 . "OCR lost the word in extraction")
                (R1 . "OCR fused/misread the superscript verse number into the word")
                (R2 . "OCR renders the ano teleia (·) as \" : or apostrophe, or drops the elision mark")
                (R3 . "OCR appended accent-row or margin junk")
                (R4 . "OCR dropped Swete's [ ] brackets")
                (R5 . "Latin-letter substitution in OCR"))
              k))
  (cond
   ((and (eq? ca 'R0) (eq? cb 'R0)) #f)
   ((and (memq ca %known) (memq cb %known))
    (format #f "class ~a: ~a; c read from the image strip"
            (string-join (map symbol->string (delete-duplicates (delete 'same (list ca cb)))) "+")
            (string-join (filter-map desc (delete-duplicates (list ca cb))) "; ")))
   ((or (and (eq? ca 'same) (memq cb '(OPEN DROP)))
        (and (eq? cb 'same) (memq ca '(OPEN DROP))))
    (format #f "class ~a: the other OCR reading agrees with c"
            (if (memq 'DROP (list ca cb)) "R7 (OCR dropped diacritics)" "R6 (OCR letters differ)")))
   ((and (memq ca (cons 'DROP %known)) (memq cb (cons 'DROP %known))
         (or (eq? ca 'same) (eq? cb 'same)))
    "class R7: OCR dropped diacritics; the other OCR reading agrees with c")
   (else #f)))

(define %enclitics
  (map base-letters
       '("μου" "μοι" "με" "σου" "σοι" "σε" "τις" "τι" "τινος" "τινι" "τινα" "τινες" "τινων" "τισι" "τισιν"
         "τινας" "πως" "που" "ποτε" "πω" "γε" "τε" "τοι" "περ" "ειμι" "εισι" "εισιν" "εστι" "εστιν" "εσμεν"
         "εστε" "φημι" "φησι" "φησιν" "φασι" "φασιν")))

(define %grave-words
  ;; Articles, prepositions and particles: Swete's grave before a capital is not in doubt.
  (map base-letters '("ο" "η" "το" "οι" "αι" "τα" "του" "της" "των" "τω" "τη" "τον" "την" "τοις" "ταις" "τους" "τας"
                      "προς" "επι" "απο" "υπο" "δια" "κατα" "μετα" "παρα" "περι" "ανα" "αντι" "υπερ" "εν" "εκ" "εις"
                      "δε" "και" "μεν" "γαρ" "ουδε" "μηδε" "αλλα" "ουν" "ητοι" "ως" "ουκ" "ουχ" "μη" "ου")))

(define (word-core t) (string-trim-both t (char-set-adjoin (string->char-set ".,·;:[]()¶§") #\-)))

(define (capital-breathing? t)
  "A breathing on a capital, or on the ι/υ of a capitalized diphthong (Εὑ, Αὐ)."
  (let ((breathing? (lambda (letter) (any (lambda (c) (memv c '(#\x313 #\x314))) (cdr letter)))))
    (match (marks-of t)
      (((? (lambda (l) (and (greek-char? (car l)) (char-upper-case? (car l)))) first) . rest)
       (or (breathing? first)
           (match rest
             ((second . _) (and (memv (car second) '(#\ι #\υ)) (breathing? second)))
             (_ #f))))
      (_ #f))))

(define (accents t)
  "Accent marks of T in order (NFD acute, grave, circumflex)."
  (filter (lambda (c) (memv c '(#\x301 #\x300 #\x342))) (string->list (string-normalize-nfd t))))

(define (vowel-groups-after-accent t)
  "Vowel groups after the last accented vowel's group (0 = accent on the last syllable)."
  (let* ((cs (string->list (string-normalize-nfd (word-core t))))
         (after (take-while (lambda (c) (not (memv c '(#\x301 #\x300 #\x342)))) (reverse cs)))
         (vowel? (lambda (c) (memv c (string->list "αεηιουωΑΕΗΙΟΥΩ")))))
    ;; count runs of vowels in AFTER (reversed tail); a vowel right after the
    ;; accent that continues its diphthong (ι, υ) is still the same syllable
    (let loop ((cs (reverse after)) (in? #t) (n 0))
      (match cs
        (() n)
        ((c . rest)
         (cond ((combining? c) (loop rest in? n))
               ((vowel? c) (loop rest #t (if in? n (+ n 1))))
               (else (loop rest #f n))))))))

(define (oxytone? t)
  "Acute or grave with no vowel after it (accent on the last syllable)."
  (let* ((cs (string->list (string-normalize-nfd (word-core t))))
         (tail (find-tail (lambda (c) (memv c '(#\x301 #\x300))) (reverse cs))))
    (and tail (not (any (lambda (c) (memv c (string->list "αεηιουωΑΕΗΙΟΥΩ"))) (take-while (negate (lambda (c) (memv c '(#\x301 #\x300)))) (reverse cs)))))))

(define (hazards toks i)
  "Mandatory zoom checks for our token I: H1 breathing on a capital, H2 accent
before an enclitic, H3 accent (Swete's acute) before a capitalized word."
  (let* ((t (first (vector-ref toks i)))
         (next (and (< (+ i 1) (vector-length toks)) (first (vector-ref toks (+ i 1)))))
         (core (word-core t))
         (ends-sentence? (and (> (string-length t) 0) (memv (string-ref t (- (string-length t) 1)) '(#\. #\· #\;))))
         (next-core (and next (word-core next))))
    (filter-map
     (lambda (p) (and (cdr p) (car p)))
     (list (cons 'H1 (capital-breathing? core))
           ;; Before an unaccented enclitic the accent changes only on an oxytone
           ;; (acute stays), a proparoxytone or properispomenon (second acute).
           (cons 'H2 (and next-core (member (base-letters next-core) %enclitics)
                          (null? (accents next-core))
                          (or (oxytone? core)
                              (>= (length (accents core)) 2)
                              (>= (vowel-groups-after-accent core) 2)
                              (and (equal? (accents core) '(#\x342)) (= (vowel-groups-after-accent core) 1)))
                          #t))
           (cons 'H3 (and next-core (> (string-length next-core) 0) (not ends-sentence?)
                          (greek-char? (string-ref next-core 0)) (char-upper-case? (string-ref next-core 0))
                          (oxytone? core) (not (member (base-letters core) %grave-words))))))))

(define (collate c-toks a-toks b-toks)
  "Rows for every token of our reading C-TOKS ((text line at-verse?)) that
either OCR reading (A-TOKS, B-TOKS: (text word line-index)) gets differently,
or that a mandatory check covers. Each row is an alist with keys: i line kind
c a b class-a class-b hazards basis (#f = needs a zoom) word (an OCR word box
for the crop, or #f) next-word."
  (let* ((cv (list->vector c-toks))
         (ctexts (list->vector (map first c-toks)))
         (av (list->vector a-toks)) (bv (list->vector b-toks))
         (atexts (list->vector (map first a-toks))) (btexts (list->vector (map first b-toks)))
         (am (align ctexts atexts)) (bm (align ctexts btexts)))
    (define (main texts entry) (and (pair? (car entry)) (string-join (map (lambda (j) (vector-ref texts j)) (car entry)) " ")))
    (define (word-of i)
      ;; The OCR word the token was read as: same letters if any, else the longest.
      (let* ((c (and (< -1 i (vector-length cv)) (base-letters (first (vector-ref cv i)))))
             (from (lambda (m v)
                     (and c (< -1 i (vector-length m))
                          (let ((js (append (car (vector-ref m i)) (cdr (vector-ref m i)))))
                            (and (pair? js)
                                 (let ((ws (map (lambda (j) (vector-ref v j)) js)))
                                   (second (or (find (lambda (w) (string=? (base-letters (first w)) c)) ws)
                                               (fold (lambda (w best) (if (> (string-length (first w)) (string-length (first best))) w best))
                                                     (car ws) ws))))))))))
        (or (from bm bv) (from am av))))
    (filter-map
     (lambda (i)
       (match (vector-ref cv i)
         ((c line at-verse?)
          (let* ((ae (vector-ref am i)) (be (vector-ref bm i))
                 (ca (classify c (main atexts ae) (map (lambda (j) (vector-ref atexts j)) (cdr ae)) at-verse?))
                 (cb (classify c (main btexts be) (map (lambda (j) (vector-ref btexts j)) (cdr be)) at-verse?))
                 (hz (hazards cv i))
                 (a (reading atexts ae)) (b (reading btexts be)))
            (and (or (pair? hz) (not (and (eq? ca 'same) (eq? cb 'same))))
                 `((i . ,i) (line . ,line)
                   (kind . ,(cond ((and (string=? a c) (string=? b c)) "A=B=C")
                                  ((string=? a b) "A=B≠C")
                                  ((string=? b c) "A≠C")
                                  ((string=? a c) "B≠C")
                                  (else "ALL≠")))
                   (c . ,c) (a . ,a) (b . ,b) (class-a . ,ca) (class-b . ,cb) (hazards . ,hz)
                   (basis . ,(and (null? hz) (class-basis ca cb)))
                   (word . ,(word-of i))
                   (next-word . ,(and (memq 'H2 hz) (word-of (+ i 1))))))))))
     (iota (vector-length cv)))))

;;; ---------------------------------------------------------------------------
;;; Decision rows
;;; ---------------------------------------------------------------------------
;; A decision row: book scan leaf line reading_a reading_b reading_c_first chosen basis.

(define (todo? d) (string-prefix? "TODO" (ninth d)))

(define (reconcile rows old)
  "Match collate ROWS to the OLD decision rows. Returns (values matches
decisions orphans): MATCHES the decision index of each row; DECISIONS the new
decision list, with #f where a row needs a new decision; ORPHANS the indexes of
settled decisions no row matches. Matching, in order: the same line and OCR
readings; else a settled decision for the same token (our reading is its first
or chosen reading) with the same OCR readings on another line (a line was added
or removed), or on the same line with other OCR readings (the box changed). A
carried-over decision takes the row's new line and readings and keeps its
choice and basis. A TODO row that matches nothing is stale and dropped: it
settled nothing, and done would otherwise count it while collate did not; a
settled decision or a flag is never dropped."
  (let* ((ov (list->vector old))
         (n (vector-length ov))
         (used (make-vector n #f))
         (rv (list->vector rows))
         (m (make-vector (vector-length rv) #f))
         (line-of (lambda (r) (number->string (assq-ref r 'line))))
         (settled? (lambda (d) (not (todo? d))))
         (flag? (lambda (d) (and (string=? (fifth d) "-") (string=? (sixth d) "-")))))
    (define (claim! k pred)
      (unless (vector-ref m k)
        (let ((i (find (lambda (i) (and (not (vector-ref used i)) (pred (vector-ref ov i) (vector-ref rv k)))) (iota n))))
          (when i
            (vector-set! used i #t)
            (vector-set! m k i)
            (let ((d (vector-ref ov i)) (r (vector-ref rv k)))
              (vector-set! ov i (append (take d 3) (list (line-of r) (assq-ref r 'a) (assq-ref r 'b)) (drop d 6))))))))
    (define (same-token? d r) (and (settled? d) (not (flag? d)) (member (assq-ref r 'c) (list (seventh d) (eighth d)))))
    (for-each (lambda (k) (claim! k (lambda (d r) (equal? (list (fourth d) (fifth d) (sixth d))
                                                          (list (line-of r) (assq-ref r 'a) (assq-ref r 'b))))))
              (iota (vector-length rv)))
    (for-each (lambda (k) (claim! k (lambda (d r) (and (same-token? d r) (string=? (fifth d) (assq-ref r 'a))
                                                       (string=? (sixth d) (assq-ref r 'b))))))
              (iota (vector-length rv)))
    (for-each (lambda (k) (claim! k (lambda (d r) (and (same-token? d r) (string=? (fourth d) (line-of r))))))
              (iota (vector-length rv)))
    ;; Keep matched and settled old rows in their order, drop stale TODOs,
    ;; append one new slot per unmatched row.
    (let* ((kept (filter (lambda (i) (or (vector-ref used i) (settled? (vector-ref ov i)))) (iota n)))
           (pos (map cons kept (iota (length kept))))
           (unmatched (filter (lambda (k) (not (vector-ref m k))) (iota (vector-length rv))))
           (new-pos (map cons unmatched (iota (length unmatched) (length kept)))))
      (values (map (lambda (k) (if (vector-ref m k) (assv-ref pos (vector-ref m k)) (assv-ref new-pos k)))
                   (iota (vector-length rv)))
              (append (map (lambda (i) (vector-ref ov i)) kept) (map (const #f) unmatched))
              (filter-map (lambda (i) (and (not (vector-ref used i)) (not (flag? (vector-ref ov i))) (assv-ref pos i))) kept)))))
