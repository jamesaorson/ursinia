;; Copyright (C) 2026
;;
;; Check the Greek Source Bible translation files (gsb/translation/) against
;; the Greek tables (gsb/greek/), the concordance (gsb/lexicon/glosses.scm) and
;; the readable layer's avoid list (gsb/lexicon/readable-avoid.scm); or, with
;; --uses, list where a lemma is used. The rules live in (scripts lib
;; gsb-translation); the format is documented in gsb/translation/README.md.
;; Invoked through ./scripts/gsb-check.sh.

(use-modules (scripts lib gsb-translation)
             (ice-9 format)
             (ice-9 match)
             (srfi srfi-1)
             (srfi srfi-11)
             (srfi srfi-13))

(define %glosses "gsb/lexicon/glosses.scm")
(define %avoid "gsb/lexicon/readable-avoid.scm")

(define (usage port)
  (format port "Usage: ./scripts/gsb-check.sh [-h|--help]~%")
  (format port "       ./scripts/gsb-check.sh --uses LEMMA~%~%")
  (format port "With no arguments, check every Greek Source Bible translation file in~%")
  (format port "gsb/translation/:~%")
  (format port "  - every Greek word of a translated verse is aligned to exactly one literal~%")
  (format port "    segment or listed in (untranslated (N \"reason\")); (cont N) continues~%")
  (format port "    an earlier segment's word~%")
  (format port "  - [supplied] words have no Greek; any other words do~%")
  (format port "  - unbracketed \"the\"/\"a\"/\"an\" has a Greek article behind it~%")
  (format port "  - each aligned word's lemma and sense are in ~a (a bare~%" %glosses)
  (format port "    number means the first sense listed) and the segment uses its gloss~%")
  (format port "  - the source's ambiguity is kept: no personal pronoun or name for a~%")
  (format port "    demonstrative, no name the Greek does not say (warnings do not fail)~%")
  (format port "  - the readable layer avoids the words in ~a~%" %avoid)
  (format port "  - refs and word numbers exist in gsb/greek/; status is draft or reviewed~%")
  (format port "Exits 1 and names file, verse and fix for each problem. Run as `make gsb/lint`.~%~%")
  (format port "--uses LEMMA lists every literal-layer use of LEMMA (as in gsb/greek/ and~%")
  (format port "the concordance, e.g. ἀρχή) with its sense and English: review them after~%")
  (format port "adding a sense. Run as `make gsb/uses LEMMA=ἀρχή`.~%~%")
  (format port "Format and worked examples: gsb/translation/README.md.~%"))

(define (safe-read-forms path)
  "Forms of PATH, or a string describing why it could not be read."
  (catch #t
    (lambda () (read-forms path))
    (lambda (key . args)
      (format #f "~a: cannot be read as Scheme data (~a); check for an unbalanced parenthesis or an unescaped \" inside a string"
              path key))))

(define (book-chapters book)
  "BOOK's chapter files as (path chapter forms-or-error-string), book.scm included
with chapter #f."
  (let ((dir (translation-dir book)))
    (map (lambda (name)
           (let ((path (string-append dir "/" name)))
             (list path (chapter-file-number name) (safe-read-forms path))))
         (chapter-files book))))

(define (check-book book glosses avoid warn)
  (let* ((dir (translation-dir book))
         (table-path (greek-table-path book))
         (files (book-chapters book))
         (verses (and (file-exists? table-path) (read-greek-table table-path))))
    (cond
     ((null? files) '())
     ((not verses)
      (list (format #f "~a: no Greek table ~a; run `make gsb` (or wait until the book is transcribed) before translating it"
                    dir table-path)))
     (else
      (append-map
       (match-lambda
         ((path chapter forms)
          (cond
           ((string? forms) (list forms))
           ((string-suffix? "/book.scm" path)
            (filter-map (match-lambda
                          (('note (? string?)) #f)
                          (x (format #f "~a: book files hold only (note \"...\") forms, got ~s" path x)))
                        forms))
           ((not chapter)
            (list (format #f "~a: chapter files are named by three-digit chapter number (001.scm); rename it" path)))
           (else (check-chapter path (book-field book 'id) chapter forms verses glosses
                                #:avoid avoid #:warn warn)))))
       files)))))

(define (read-checked path check what)
  "(values forms errors) for an optional data file PATH checked by CHECK."
  (let ((forms (if (file-exists? path) (safe-read-forms path) '())))
    (if (string? forms)
        (values '() (list forms))
        (values forms (map (lambda (m) (string-append path ": " m)) (check forms))))))

(define (uses books glosses lemma)
  "Print every literal-layer use of LEMMA; exit 1 if there is none."
  (let* ((lemma (string-normalize-nfc lemma))
         (senses (hash-ref glosses lemma))
         (found 0))
    (if senses
        (format #t "~a: senses ~{~a~^, ~} (default: ~a)~%" lemma (map car senses) (caar senses))
        (format #t "~a: not in ~a~%" lemma %glosses))
    (for-each
     (lambda (book)
       (let ((table-path (greek-table-path book)))
         (when (file-exists? table-path)
           (let ((verses (read-greek-table table-path)))
             (for-each
              (match-lambda
                ((path chapter (? pair? forms))
                 (when chapter
                   (for-each
                    (match-lambda
                      (('verse num . _)
                       (let* ((form (cons* 'verse num (cddr (assoc-ref (map (lambda (f) (cons (cadr f) f))
                                                                             (filter (lambda (f) (and (pair? f) (eq? (car f) 'verse))) forms))
                                                                        num))))
                              (ref (format #f "~a.~a.~a" (book-field book 'id) chapter num))
                              (words (assoc-ref verses ref)))
                         (when words
                           (for-each
                            (match-lambda
                              ((n l sense default? english)
                               (when (string=? l lemma)
                                 (set! found (+ found 1))
                                 (let ((w (find (lambda (w) (eqv? (word-n w) n)) words)))
                                   (format #t "~a#~a\t~a\t~a~a\t~s~%" ref n (word-text* w) sense
                                           (if default? " (default)" "") english)))))
                            (verse-uses form words glosses)))))
                      (_ #f))
                    forms)))
                (_ #f))
              (book-chapters book))))))
     books)
    (when (zero? found)
      (format (current-error-port) "gsb-check: no literal-layer use of ~a; check the spelling against the lemma column of gsb/greek/ or ~a~%" lemma %glosses)
      (exit 1))))

(define (main args)
  (when (or (member "-h" args) (member "--help" args))
    (usage (current-output-port))
    (exit 0))
  (unless (file-exists? "gsb/greek")
    (format (current-error-port) "gsb-check: Greek tables missing (gsb/greek/); run `make gsb`~%")
    (exit 1))
  (let*-values (((books) (read-books))
                ((gloss-forms gloss-errors) (read-checked %glosses check-glosses "concordance"))
                ((avoid-forms avoid-errors) (read-checked %avoid check-avoid "avoid list"))
                ((glosses) (parse-glosses (if (null? gloss-errors) gloss-forms '())))
                ((avoid) (if (null? avoid-errors) (parse-avoid avoid-forms) '())))
    (match (cdr args)
      (("--uses" lemma) (uses books glosses lemma) (exit 0))
      (("--uses")
       (format (current-error-port) "gsb-check: --uses needs a lemma, e.g. ./scripts/gsb-check.sh --uses ἀρχή (or make gsb/uses LEMMA=ἀρχή)~%")
       (exit 2))
      (() #t)
      (_ (usage (current-error-port)) (exit 2)))
    (let* ((stems (map book-file-stem books))
           (warnings '())
           (warn (lambda (w) (set! warnings (cons w warnings))))
           (stray (filter-map (lambda (d)
                                (and (not (member d (cons* "." ".." "README.md" stems)))
                                     (format #f "gsb/translation/~a: not a book directory; book directories are named NN-<id> from gsb/books.tsv" d)))
                              (let ((dir (opendir "gsb/translation")))
                                (let loop ((acc '()))
                                  (let ((e (readdir dir)))
                                    (if (eof-object? e) (begin (closedir dir) (sort acc string<?)) (loop (cons e acc))))))))
           (errors (append gloss-errors avoid-errors stray
                           (append-map (lambda (b) (check-book b glosses avoid warn)) books)))
           (chapters (apply + (map (lambda (b) (length (filter chapter-file-number (chapter-files b)))) books))))
      (for-each (lambda (w) (format (current-error-port) "~a~%" w)) (reverse warnings))
      (for-each (lambda (e) (format (current-error-port) "~a~%" e)) errors)
      (if (null? errors)
          (format #t "gsb-check: ~a chapter file(s), the concordance and the avoid list pass~a~%" chapters
                  (if (null? warnings) "" (format #f " (~a warning~:p above; review them)" (length warnings))))
          (begin
            (format (current-error-port) "gsb-check: ~a problem(s); fix them and rerun `make gsb/lint`~%" (length errors))
            (exit 1))))))

(main (command-line))
