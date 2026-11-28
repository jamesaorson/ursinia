;; Copyright (C) 2026
;;
;; Generate the Greek Source Bible's hyper-literal English (gsb/literal/) from
;; the Greek tables, our form analyses, the concordance, fixed phrases and
;; per-word overrides; list the data still missing; check it; compare it with
;; the hand-made drafts. Rules and formats: gsb/literal/README.md. Invoked
;; through ./scripts/gsb-literal.sh.

(use-modules (scripts lib gsb)
             (scripts lib gsb-translation)
             (scripts lib gsb-literal)
             (ice-9 format)
             (ice-9 ftw)
             (ice-9 match)
             (ice-9 regex)
             (srfi srfi-1)
             (srfi srfi-11)
             (srfi srfi-13))

(define %out "gsb/literal")
(define %forms-dir "gsb/literal/forms")
(define %overrides-dir "gsb/literal/overrides")
(define %phrases "gsb/literal/phrases.scm")
(define %glosses "gsb/lexicon/glosses/")

(define (usage port)
  (format port "Usage: ./scripts/gsb-literal.sh COMMAND [BOOK [CHAPTER ...]]~%~%")
  (format port "Commands (BOOK is an id from gsb/books.tsv, e.g. gen, exod):~%")
  (format port "  generate [BOOK CHAPTER ...]  write gsb/literal/NN-<id>/CCC.scm; with no BOOK,~%")
  (format port "                               regenerate every chapter already there (make gsb/literal)~%")
  (format port "  todo BOOK [CHAPTER ...]      list forms with no analysis and lemmas not in the~%")
  (format port "                               concordance, with a context line, as TSV to fill in~%")
  (format port "  check [BOOK CHAPTER ...]     check the data behind the chapters (unknown forms,~%")
  (format port "                               lemmas/senses missing, article-noun disagreement)~%")
  (format port "                               and lint the generated text (make gsb/literal/check)~%")
  (format port "  compare BOOK CHAPTER         verse-by-verse against the hand draft in gsb/translation/~%")
  (format port "  stats BOOK ...               distinct forms and lemmas still unanalyzed per book~%")
  (format port "  explain REF                  each word of one verse (gen.1.1): reading, sense, role~%")
  (format port "  show BOOK CHAPTER [--greek]  the generated chapter as plain text (with the Greek)~%~%")
  (format port "Data: gsb/literal/forms/NN-<id>.tsv (form analyses), gsb/literal/overrides/NN-<id>.scm,~%")
  (format port "gsb/literal/phrases.scm, gsb/lexicon/glosses/*.scm. Formats: gsb/literal/README.md.~%"))

(define (die fmt . args)
  (apply format (current-error-port) (string-append "gsb-literal: " fmt "~%") args)
  (exit 1))

(define (dir-files dir suffix)
  (if (file-exists? dir)
      (map (lambda (f) (string-append dir "/" f))
           (sort (filter (lambda (f) (string-suffix? suffix f)) (or (scandir dir) '())) string<?))
      '()))

;;; Loading the data (scripts/lib/gsb-literal.scm, shared with the database loader).

(define (load-env)
  (unless (file-exists? "gsb/greek") (die "Greek tables missing (gsb/greek/); run `make gsb`"))
  (let ((errors (check-gloss-files (map (lambda (p) (cons p (read-forms p))) (gloss-files)))))
    (unless (null? errors)
      (for-each (lambda (e) (format (current-error-port) "error\t~a~%" e)) errors)
      (die "fix the concordance above (gsb/lexicon/glosses/; `make gsb/lint` checks it)")))
  (call-with-values load-literal-env
    (lambda (env problems)
      (unless (null? problems)
        (for-each (lambda (p) (format (current-error-port) "~a~%" p)) problems)
        (die "fix the data files above (formats: gsb/literal/README.md)"))
      env)))

(define (find-book id)
  (or (find (lambda (b) (equal? (book-field b 'id) id)) (read-books))
      (die "no book ~s in gsb/books.tsv; use its id column (gen, exod, ...)" id)))

(define (chapter-verses verses id chapter)
  (let ((prefix (format #f "~a.~a." id chapter)))
    (filter (lambda (v) (string-prefix? prefix (car v))) verses)))

(define (verse-number ref)
  (let* ((s (last (string-split ref #\.))) (n (string->number s))) (or n s)))

(define (out-path book chapter) (literal-chapter-path book chapter))

(define (book-verses book)
  (let ((p (greek-table-path book)))
    (unless (file-exists? p) (die "no Greek table ~a; the book is not transcribed yet (or run `make gsb`)" p))
    (read-greek-table p)))

(define (parse-chapters book args)
  ;; a number, or the capital letter of a lettered addition (Esther A-F)
  (map (lambda (a) (or (chapter-arg a)
                       (die "chapter ~s is not a positive number or a capital letter (Esther's additions: A-F)" a)))
       args))

;;; Generating.

(define (table-lemmas words)
  (let ((h (make-hash-table))) (for-each (lambda (w) (hash-set! h (word-n w) (word-lemma* w))) words) h))

(define (chapter-text env book chapter verses)
  (let loop ((vs (chapter-verses verses (book-field book 'id) chapter)) (stop? #t) (prev '()) (acc '()))
    (match vs
      (() (reverse acc))
      (((ref . words) . rest)
       (let ((pin (hash-ref (env-pins* env) ref)))
         (if pin
             (loop rest #t words (cons (cons (verse-number ref) pin) acc))
             ;; ponytail: antecedents only within the verse; the verse before
             ;; (prev) picked wrong ones in dialogue (Gen 3:11 "said to it").
             (call-with-values (lambda () (render-verse env ref words stop?))
               (lambda (segs full-stop?)
                 (loop rest full-stop? words
                       (cons (cons (verse-number ref) (segments->sexp env segs (table-lemmas words))) acc))))))))))

(define env-pins* env-pins)

(define %header
  ";; GENERATED by ./scripts/gsb-literal.sh (make gsb/literal): do not edit.
;; Change the data instead (gsb/literal/forms, gsb/literal/overrides,
;; gsb/literal/phrases.scm, gsb/lexicon/glosses/) and regenerate.
;; Segment format: gsb/translation/README.md. Rules: gsb/literal/README.md.
")

(define (generate env book chapters)
  (let ((verses (book-verses book)))
    (for-each
     (lambda (c)
       (let ((vs (chapter-text env book c verses)))
         (when (null? vs) (die "~a has no chapter ~a in ~a" (book-field book 'id) c (greek-table-path book)))
         (let ((status (write-if-changed (out-path book c)
                                         (call-with-output-string (lambda (port) (write-chapter port %header vs)))
                                         #f)))
           (format #t "~a ~a~%" (if (eq? status 'wrote) "wrote" "unchanged") (out-path book c)))))
     chapters)))

(define (existing-chapters)
  "(book . chapters) for every chapter file already in gsb/literal/."
  (filter-map (lambda (b)
                (let ((cs (filter-map (lambda (p) (literal-chapter-key (basename p)))
                                      (dir-files (string-append %out "/" (book-file-stem b)) ".scm"))))
                  (and (pair? cs) (cons b (sort cs chapter<?)))))
              (read-books)))

(define (targets args)
  (match args
    (() (let ((ex (existing-chapters)))
          (when (null? ex) (die "nothing generated yet; run ./scripts/gsb-literal.sh generate gen 1 (a book id and chapters)"))
          ex))
    ((id) (die "give the chapters too: ./scripts/gsb-literal.sh <command> ~a 1 2 3" id))
    ((id . cs) (let ((b (find-book id))) (list (cons b (parse-chapters b cs)))))))

;;; todo / check.

(define (verse-text words)
  (string-join (map (lambda (w) (string-append (word-pre* w) (word-text* w) (word-post* w))) words) " "))

(define (todo env book chapters)
  (let* ((verses (book-verses book))
         (seen (make-hash-table)) (order '()))
    (for-each
     (lambda (c)
       (for-each (match-lambda
                   ((ref . words)
                    (for-each (match-lambda
                                ((kind at greek detail)
                                 (let ((k (list kind (form-key greek) detail)))
                                   (unless (hash-ref seen k) (set! order (cons (list k at greek detail (verse-text words)) order)))
                                   (hash-set! seen k (+ 1 (hash-ref seen k 0))))))
                              (filter (lambda (p) (memq (car p) '(unknown-form lemma-not-in-glosses no-such-sense)))
                                      (verse-problems env ref words)))))
                 (chapter-verses verses (book-field book 'id) c)))
     chapters)
    (format #t "kind\tform\tcount\ttable-lemma\tfirst\tcontext~%")
    (for-each (match-lambda
                ((k at greek detail ctx)
                 (format #t "~a\t~a\t~a\t~a\t~a\t~a~%" (car k) greek (hash-ref seen k) detail at ctx)))
              (reverse order))))

(define (lint-generated env book chapter)
  "check-chapter errors for a generated chapter (readable layer not required)."
  (let* ((path (out-path book chapter))
         (forms (map (match-lambda
                       (('verse n items ...) `(verse ,n ,@items (readable "generated")))
                       (x x))
                     (read-forms path)))
         (glosses (parse-glosses (read-gloss-forms))))
    (check-chapter path (book-field book 'id) chapter forms (book-verses book) glosses)))

(define (english-problems heads book chapter)
  "(error|warning kind ref text detail) for the English of a generated
chapter: a word doubled inside one segment (\"came back back\": a (verb ...)
field's particle given twice) is an error; a suspicious -ing/-ed spelling a
warning (`doubles?` in scripts/lib/gsb-literal.scm)."
  (append-map
   (match-lambda
     (('verse n items ...)
      (let ((ref (format #f "~a.~a.~a" (book-field book 'id) chapter n))
            (segs (filter (lambda (s) (and (pair? s) (string? (car s)))) (or (assq-ref items 'literal) '()))))
        (append-map
         (lambda (s)
           (let* ((text (car s))
                  (ws (string-tokenize (string-downcase text) char-set:letter))
                  (doubled (let loop ((ws ws))
                             (cond ((or (null? ws) (null? (cdr ws))) #f)
                                   ((string=? (car ws) (cadr ws)) (car ws))
                                   (else (loop (cdr ws)))))))
             (append
              (if doubled
                  (list (list 'error 'doubled-word ref text (format #f "~s twice in one segment; write a (verb ...) field's past forms once (gsb/literal/README.md)" doubled)))
                  '())
              (filter-map (lambda (w) (and (suspicious-spelling? heads w)
                                           (list 'warning 'spelling ref text
                                                 (format #f "~s: a longer verb ending consonant-vowel-consonant; if its stress is final add it to %double, else to %stress-initial (scripts/lib/gsb-literal.scm)" w))))
                          ws))))
         segs)))
     (_ '()))
   (read-forms (out-path book chapter))))

(define (check env tgts)
  "Errors (unknown form, lemma or sense missing from the concordance, an
article that does not agree, any lint error in the output, a chapter not
generated) fail; warnings (ambiguous New Testament reading, pinned verse,
verse mostly overrides) are listed."
  (let ((problems 0) (warnings 0) (heads (verb-heads env)))
    (define (problem! fmt . args) (set! problems (+ problems 1)) (apply format #t (string-append "error\t" fmt "~%") args))
    (define (warning! fmt . args) (set! warnings (+ warnings 1)) (apply format #t (string-append "warning\t" fmt "~%") args))
    (for-each
     (match-lambda
       ((book . chapters)
        (let ((verses (book-verses book)))
          (for-each
           (lambda (c)
             (for-each (match-lambda
                         ((ref . words)
                          (if (hash-ref (env-pins* env) ref)
                              (warning! "pinned-verse\t~a\t\tcheck it still matches the rules (gsb/literal/overrides)" ref)
                              (begin
                                (for-each (match-lambda ((kind at greek detail) (problem! "~a\t~a\t~a\t~a" kind at greek detail)))
                                          (verse-problems env ref words))
                                (for-each (match-lambda ((kind at greek detail) (warning! "~a\t~a\t~a\t~a" kind at greek detail)))
                                          (verse-warnings env ref words))))))
                       (chapter-verses verses (book-field book 'id) c))
             (if (file-exists? (out-path book c))
                 (begin
                   (for-each (lambda (e) (problem! "lint\t~a" e)) (lint-generated env book c))
                   (for-each (match-lambda
                               (('error kind ref text detail) (problem! "~a\t~a\t~s\t~a" kind ref text detail))
                               (('warning kind ref text detail) (warning! "~a\t~a\t~s\t~a" kind ref text detail)))
                             (english-problems heads book c)))
                 (problem! "not-generated\t~a\trun ./scripts/gsb-literal.sh generate ~a ~a" (out-path book c) (book-field book 'id) c)))
           chapters))))
     tgts)
    (cond
     ((positive? problems)
      (format (current-error-port) "gsb-literal: ~a error(s), ~a warning(s); add analyses with `todo`, glosses to ~a, or overrides (gsb/literal/README.md)~%"
              problems warnings %glosses)
      (exit 1))
     (else (format #t "gsb-literal: data and generated text pass (~a warning~:p above; review them)~%" warnings)))))

;;; compare.

(define (literal-text items) (segments-text (filter pair? (literal-segments items))))

(define (compare env book chapter)
  (let* ((hand-path (format #f "gsb/translation/~a/~a.scm" (book-file-stem book) (if (number? chapter) (format #f "~3,'0d" chapter) chapter)))
         (gen-path (out-path book chapter)))
    (unless (file-exists? hand-path) (die "no hand draft ~a to compare with" hand-path))
    (unless (file-exists? gen-path) (die "~a not generated; run ./scripts/gsb-literal.sh generate ~a ~a" gen-path (book-field book 'id) chapter))
    (let* ((by-num (lambda (path) (filter-map (match-lambda (('verse n items ...) (cons n (literal-text (or (assq-ref items 'literal) (let ((l (find (lambda (i) (and (pair? i) (eq? (car i) 'literal))) items))) (if l (cdr l) '())))))) (_ #f)) (read-forms path))))
           (hand (by-num hand-path)) (gen (by-num gen-path))
           (counts (make-hash-table)))
      (for-each (match-lambda
                  ((n . g)
                   (let* ((h (or (assoc-ref hand n) ""))
                          (kind (cond ((string=? g h) 'identical)
                                      ((string=? (normalize-for-compare g #f) (normalize-for-compare h #f)) 'punctuation-brackets)
                                      ((string=? (normalize-for-compare g #t) (normalize-for-compare h #t)) 'supplied-words)
                                      (else 'differs))))
                     (hash-set! counts kind (+ 1 (hash-ref counts kind 0)))
                     (format #t "~a:~a ~a~%  hand: ~a~%  gen:  ~a~%" chapter n kind h g))))
                gen)
      (format #t "~%summary ~a ~a: ~{~a~^, ~}~%" (book-field book 'id) chapter
              (map (lambda (k) (format #f "~a ~a" (hash-ref counts k 0) k)) '(identical punctuation-brackets supplied-words differs))))))

;;; stats.

(define (stats env ids)
  (for-each
   (lambda (id)
     (let* ((book (find-book id)) (verses (book-verses book))
            (forms (make-hash-table)) (lemmas (make-hash-table)) (tokens 0) (unknown 0))
       (for-each (match-lambda
                   ((ref . words)
                    (for-each (match-lambda
                                ((kind at greek detail)
                                 (case kind
                                   ((unknown-form) (set! unknown (+ unknown 1)) (hash-set! forms (form-key greek) #t))
                                   ((lemma-not-in-glosses) (hash-set! lemmas detail #t)))))
                              (verse-problems env ref words))
                    (set! tokens (+ tokens (length words)))))
                 verses)
       (format #t "~a\ttokens ~a\tunanalyzed tokens ~a\tdistinct unanalyzed forms ~a\tlemmas not in glosses ~a~%"
               id tokens unknown (hash-count (const #t) forms) (hash-count (const #t) lemmas))))
   ids))

(define (main args)
  (match (cdr args)
    ((or () ((or "-h" "--help" "help") . _)) (usage (current-output-port)) (exit (if (null? (cdr args)) 2 0)))
    (("generate" . rest) (let ((env (load-env))) (for-each (match-lambda ((b . cs) (generate env b cs))) (targets rest))))
    (("todo" id . cs)
     (let* ((b (find-book id)) (env (load-env)))
       (todo env b (if (null? cs)
                       (delete-duplicates (filter-map (lambda (v) (chapter-arg (cadr (string-split (car v) #\.)))) (book-verses b)))
                       (parse-chapters b cs)))))
    (("todo") (die "todo needs a book: ./scripts/gsb-literal.sh todo gen 4"))
    (("check" . rest) (check (load-env) (targets rest)))
    (("compare" id c) (compare (load-env) (find-book id) (car (parse-chapters #f (list c)))))
    (("compare" . _) (die "compare needs a book and one chapter: ./scripts/gsb-literal.sh compare gen 1"))
    (("stats" . (? pair? ids)) (stats (load-env) ids))
    (("explain" ref)
     (let* ((id (car (string-split ref #\.)))
            (words (or (assoc-ref (book-verses (find-book id)) ref) (die "no verse ~a in the Greek table" ref))))
       (format #t "n\tgreek\tlemma\ttag\tsense\trole\thelper~%")
       (for-each (lambda (l) (format #t "~a~%" l)) (explain-verse (load-env) ref words))))
    (("explain" . _) (die "explain needs one verse reference: ./scripts/gsb-literal.sh explain gen.1.1"))
    (("show" id c . flags)
     (let* ((book (find-book id)) (chapter (car (parse-chapters book (list c))))
            (path (out-path book chapter))
            (verses (book-verses book)))
       (unless (file-exists? path) (die "~a not generated; run ./scripts/gsb-literal.sh generate ~a ~a" path id chapter))
       (for-each (match-lambda
                   (('verse n items ...)
                    (when (member "--greek" flags)
                      (format #t "~a:~a ~a~%" chapter n
                              (verse-text (or (assoc-ref verses (format #f "~a.~a.~a" id chapter n)) '()))))
                    (format #t "~a:~a ~a~%" chapter n (literal-text (cdr (assq 'literal items)))))
                   (_ #f))
                 (read-forms path))))
    (("show" . _) (die "show needs a book and chapter: ./scripts/gsb-literal.sh show gen 5 [--greek]"))
    ((cmd . _) (format (current-error-port) "gsb-literal: unknown command ~s~%~%" cmd) (usage (current-error-port)) (exit 2))))

(main (command-line))
