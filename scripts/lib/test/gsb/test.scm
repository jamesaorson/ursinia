;; Copyright (C) 2026
;;
;; Checks for (scripts lib gsb): the normalization, punctuation splitting,
;; transliteration and word diff the GSB build relies on. Run by `make test`.

(use-modules (scripts lib gsb)
             (srfi srfi-1)
             (srfi srfi-11)
             (ice-9 format))

(define failures 0)

(define-syntax-rule (check expr expected)
  (let ((actual expr))
    (unless (equal? actual expected)
      (set! failures (+ failures 1))
      (format #t "FAIL ~s~%  expected ~s~%  actual   ~s~%" 'expr expected actual))))

;; Normalization
(check (fold-key "Ἐν") "εν")
(check (fold-key "θεὸς") "θεοσ")
(check (fold-key "κατ᾽") (fold-key "κατ’"))
(check (fold-key "τῷ") "τω")
(check (compare-key "εἰσίν") (compare-key "εισι"))
(check (compare-key "εἶπεν") (compare-key "ειπε"))
(check (compare-key "οὕτως") (compare-key "ουτω"))
(check (compare-key "ἐν") "εν")                      ; too short to be movable nu
(check (grave->acute "θεὸς") "θεός")
(check (normalize-elision "κατ᾽") "κατ’")

;; Swete capitals
(check (all-caps? "ΕΝ") #t)
(check (all-caps? "ΑΡΧΗ") #t)
(check (all-caps? "Ἐν") #f)
(check (all-caps? "Ὁ") #f)
(check (capitalize-first "ἐν") "Ἐν")

;; Punctuation split
(check (split-punct "γῆν.") '("" "γῆν" "."))
(check (split-punct "“Διδάσκαλε”),") '("“" "Διδάσκαλε" "”),"))
(check (split-punct "[[Ἀναστὰς") '("[[" "Ἀναστὰς" ""))
(check (split-punct "μετ’") '("" "μετ’" ""))
(check (split-punct "ὅ,_τι") '("" "ὅ,_τι" ""))
(check (split-punct "⸆") '("⸆" "" ""))

;; Textus Receptus transliteration
(check (translit->greek "treiv") "τρεις")
(check (translit->greek "marturountev") "μαρτυρουντες")
(check (translit->greek "qeov") "θεος")
(check (translit->greek "pneuma") "πνευμα")
(check (translit->greek "x1") #f)

;; Word diff: hunks are (after deleted inserted).
(define (hunks a b)
  (diff-hunks (lcs-ops (list->vector a) (list->vector b) string=?)))
(check (hunks '("a" "b" "c") '("a" "b" "c")) '())
;; Pure insertion after base word 1 ("b").
(check (hunks '("a" "b" "c") '("a" "b" "x" "y" "c")) '((1 () (2 3))))
;; Insertion at the start and at the end.
(check (hunks '("a") '("x" "a" "y")) '((-1 () (0)) (0 () (2))))
;; Substitution: one hunk with both sides.
(check (hunks '("a" "b" "c") '("a" "x" "c")) '((0 (1) (1))))
;; Word that only the base has.
(check (hunks '("a" "b" "c") '("a" "c")) '((0 (1) ())))
;; Transposition shows up as a deletion plus an insertion of the same word,
;; which the build classifies as an order difference, never a restoration.
(check (hunks '("a" "b" "c") '("b" "a" "c")) '((-1 (0) ()) (1 () (1))))

;; Weighted pairing: the heavier match wins (Luke 2:38 αὕτη αὐτῇ / αὐτῇ).
(check (lcs-ops #("x") #("y" "x")
                (lambda (a b) (and (string=? a "x") (if (string=? b "x") 3 1))))
       '((+ 0) (= 0 1)))

;; Throwback and clitic accents.
(check (drop-throwback "εἶπέν") "εἶπεν")
(check (drop-throwback "ἀνθρώπου") "ἀνθρώπου")
(let ((t (make-hash-table)))
  (for-each (lambda (s) (index-spelling! t "εν" s)) '("ἐν" "ἐν" "Ἐν" "ἔν" "ΕΝ"))
  (check (unique-spelling t "εν") #f)                  ; ἐν/ἔν differ without #:clitics?
  (check (unique-spelling t "εν" #:clitics? #t) "ἐν"))

;; LXX stage on a typed-in fixture (Swete, Genesis 1:1-2): tokenizing,
;; capital restoration and the lemma join.
(define fixture
  (map (lambda (v) (cons (car v) (lxx-verse-words (cdr v))))
       (read-transcription "scripts/lib/test/gsb/01-gen.tsv")))
(check (map car fixture) '(("1" . "1") ("1" . "2")))
(check (map word-text (cdar fixture))
       '("ΕΝ" "ΑΡΧΗ" "ἐποίησεν" "ὁ" "θεὸς" "τὸν" "οὐρανὸν" "καὶ" "τὴν" "γῆν"))
(check (word-post (last (cdar fixture))) ".")
(define spellings (make-hash-table))
;; ΕΝ stays ambiguous (ἐν and ἕν both known); ΑΡΧΗ has one known spelling.
(for-each (lambda (s) (index-spelling! spellings (fold-key s) s)) '("ἐν" "ἕν" "ἀρχῇ"))
(define-values (decapped caps-report) (decapitalize fixture spellings))
(check (map (lambda (w) (list (word-text w) (word-flags w))) (list-head (cdar decapped) 2))
       '(("ΕΝ" ("caps")) ("ἀρχῇ" ("decap"))))
(check (map (lambda (r) (list-tail r 1)) caps-report)
       '((1 "ΕΝ" "unresolved" "") (2 "ΑΡΧΗ" "restored" "ἀρχῇ")))
(define forms (make-hash-table))
(define stripped (make-hash-table))
(let ((h (make-hash-table))) (hash-set! h '("θεός" . 2316) 5) (hash-set! forms "θεός" h))
(let ((h (make-hash-table))) (hash-set! h '("ὕδωρ" . 5204) 2) (hash-set! stripped "υδατοσ" h))
(define table
  (book-table "gen" (map (lambda (v) (cons (car v) (map (lambda (w) (lemmatize forms stripped w)) (cdr v))))
                         decapped)))
(check (list-head (string-split table #\newline) 3)
       '("ref\tn\tpre\tword\tpost\tlemma\tstrong\tmorph\tflags"
         "gen.1.1\t1\t\tΕΝ\t\t\t\t\tcaps"
         "gen.1.1\t2\t\tἀρχῇ\t\t\t\t\tdecap"))
(check (filter (lambda (line) (string-contains line "θεὸς")) (string-split table #\newline))
       '("gen.1.1\t5\t\tθεὸς\t\tθεός\tG2316\t\t"))
(check (filter (lambda (line) (string-contains line "ὕδατος")) (string-split table #\newline))
       '("gen.1.2\t19\t\tὕδατος\t.\tὕδωρ\tG5204\t\tlemma?"))

(if (zero? failures)
    (begin (format #t "gsb: all checks passed~%") (exit 0))
    (begin (format #t "gsb: ~a check(s) failed~%" failures) (exit 1)))
