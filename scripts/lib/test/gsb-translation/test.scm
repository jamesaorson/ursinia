;; Copyright (C) 2026
;;
;; Checks for (scripts lib gsb-translation): each translation-file rule fires on
;; a small broken verse and stays quiet on a good one. Run by `make test`.

(use-modules (scripts lib gsb-translation)
             (srfi srfi-1)
             (srfi srfi-13)
             (ice-9 format))

(define failures 0)

(define (fail fmt . args)
  (set! failures (+ failures 1))
  (apply format #t fmt args))

;; John 1:2-ish: Οὗτος ἦν ἐν ἀρχῇ πρὸς τὸν θεόν.
(define verses
  '(("john.1.2"
     (1 "" "Οὗτος" "" "οὗτος" "G3778" "D-NSM" ())
     (2 "" "ἦν" "" "εἰμί" "G1510" "V-IAI-3S" ())
     (3 "" "ἐν" "" "ἐν" "G1722" "PREP" ())
     (4 "" "ἀρχῇ" "" "ἀρχή" "G746" "N-DSF" ())
     (5 "" "πρὸς" "" "πρός" "G4314" "PREP" ())
     (6 "" "τὸν" "" "ὁ" "G3588" "T-ASM" ())
     (7 "" "θεόν" "." "θεός" "G2316" "N-ASM" ("tr")))))

(define gloss-forms
  '((lemma "οὗτος" (sense this (gloss "this") (why "w")))
    (lemma "εἰμί" (sense be (gloss "be" "was") (why "w")))
    (lemma "ἐν" (sense in (gloss "in") (why "w")))
    (lemma "ἀρχή" (sense beginning (gloss "beginning") (why "w")))
    (lemma "πρός" (sense with (gloss "with") (why "w")))
    (lemma "ὁ" (sense the (gloss "the") (why "w")) (sense unrendered (gloss "") (why "w")))
    (lemma "θεός" (sense god (gloss "God") (readable "God") (why "w")))
    (lemma "Ἀδάμ" (sense name (gloss "Adam") (why "w")))
    (lemma "ὄνομα" (sense name (gloss "name") (why "w")))))

(unless (null? (check-glosses gloss-forms))
  (fail "FAIL good concordance rejected: ~s~%" (check-glosses gloss-forms)))
(let ((errs (check-glosses '((lemma "x" (sense a (gloss "a"))) (lemma "x" (sense b (gloss "b") (why "w")))))))
  (unless (and (any (lambda (e) (string-contains e "why")) errs)
               (any (lambda (e) (string-contains e "twice")) errs))
    (fail "FAIL concordance problems not reported: ~s~%" errs)))
;; A lemma listed twice (compared as NFC) names both files.
(let ((errs (check-gloss-files `(("a.scm" (lemma "κατοικέω" (sense dwell (gloss "dwell") (why "w"))))
                                 ("b.scm" (lemma ,(string-normalize-nfd "κατοικέω") (sense live (gloss "live") (why "w"))))))))
  (unless (equal? errs (list (format #f "lemma ~a is listed twice: a.scm and b.scm; merge its senses into the first entry"
                                     (string-normalize-nfd "κατοικέω"))))
    (fail "FAIL duplicate lemma not reported with its files: ~s~%" errs)))
(let ((errs (check-glosses '((lemma "x" (sense a (gloss "a") (readable 3) (why "w")))))))
  (unless (any (lambda (e) (string-contains e "(readable ...)")) errs)
    (fail "FAIL bad (readable ...) in the concordance not reported: ~s~%" errs)))

(define glosses (parse-glosses gloss-forms))

;; The readable-avoid list.
(define avoid-forms '((avoid "borne" (use "moving") (why "not natural English"))))
(unless (null? (check-avoid avoid-forms))
  (fail "FAIL good avoid list rejected: ~s~%" (check-avoid avoid-forms)))
(unless (= 2 (length (check-avoid '((avoid "x" (use "y")) (avoid-word "x")))))
  (fail "FAIL bad avoid list not reported: ~s~%" (check-avoid '((avoid "x" (use "y")) (avoid-word "x")))))
(define avoid (parse-avoid avoid-forms))

(define good-literal
  '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5)
            ("God." (6 unrendered) 7)))

(define (verse . items) `(verse 2 ,@items))

(define (check items g)
  (let* ((warnings '())
         (errors (check-chapter "t.scm" "john" 1 (list (apply verse items)) verses g
                                #:avoid avoid #:warn (lambda (w) (set! warnings (cons w warnings))))))
    (values errors warnings)))

(define (errors . items)
  (call-with-values (lambda () (check items glosses)) (lambda (e w) e)))

(define-syntax-rule (expect-ok items ...)
  (let ((e (errors items ...)))
    (unless (null? e) (fail "FAIL expected no problems for ~s~%  got ~s~%" '(items ...) e))))

(define-syntax-rule (expect needle items ...)
  (let ((e (errors items ...)))
    (unless (any (lambda (m) (string-contains m needle)) e)
      (fail "FAIL expected a problem containing ~s for ~s~%  got ~s~%" needle '(items ...) e))))

(expect-ok '(status draft) good-literal '(readable "This one was in the beginning with God."))
(expect-ok '(status reviewed) good-literal '(readable ("This one was" 1 2) ("in the beginning with God." 3 4 5 6 7))
           '(note "v") '(note 7 "w"))

;; Status, layers.
(expect "missing (status draft)" good-literal '(readable "x"))
(expect "status must be" '(status done) good-literal '(readable "x"))
(expect "missing (readable" '(status draft) good-literal)
(expect "missing (literal" '(status draft) '(readable "x"))
(expect "unknown item" '(status draft) good-literal '(readable "x") '(gloss "x"))

;; Coverage: word 7 dropped, then listed as untranslated.
(define short-literal
  '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("the" (6 the))))
(expect "Greek word 7 (θεόν) is not translated" '(status draft) short-literal '(readable "x"))
(expect-ok '(status draft) short-literal '(readable "x") '(untranslated (7 "test")))
(expect "needs a reason" '(status draft) short-literal '(readable "x") '(untranslated (7 "")))

;; Brackets: wholly supplied, partly supplied, punctuation outside them.
(expect "has Greek words" '(status draft) '(literal ("[This]" 1) ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "has Greek words" '(status draft) '(literal ("[This]." 1) ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "has no Greek words" '(status draft) '(literal ("This" 1) ("one") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect-ok '(status draft) '(literal ("This [one]" 1) ("was" 2) ("in [the] beginning" 3 4) ("with" 5) ("God" (6 unrendered) 7) ("[indeed].")) '(readable "x"))
(expect "unbalanced or nested" '(status draft) '(literal ("This [one" 1) ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "unbalanced or nested" '(status draft) '(literal ("This" 1) ("[[one]]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))

;; Articles: unbracketed "the"/"a" need Greek behind them; bracketed ones do not.
(expect "no Greek article" '(status draft) '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("the beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "indefinite article" '(status draft) '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("a beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect-ok '(status draft) '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[a] beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))

;; Senses and glosses. A bare number means the first sense listed.
(expect "(the default: first listed)" '(status draft) '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." 6 7)) '(readable "x"))
(let ((unrendered-first
       (parse-glosses (map (lambda (f) (if (equal? (cadr f) "ὁ")
                                           '(lemma "ὁ" (sense unrendered (gloss "") (why "w")) (sense the (gloss "the") (why "w")))
                                           f))
                           gloss-forms))))
  (call-with-values
      (lambda () (check '((status draft) (literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." 6 7)) (readable "x"))
                        unrendered-first))
    (lambda (e w) (unless (null? e) (fail "FAIL bare ref should take the first sense: ~s~%" e)))))
(expect "has no sense" '(status draft) '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 nope) 7)) '(readable "x"))
(expect "holds none of its glosses" '(status draft) '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[the]") ("start" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))

;; Continuations: (cont N) carries word N's English on in a later segment.
(define split-literal
  '(literal ("This" 1) ("[one]") ("was" 2) ("along" 5) ("in" 3) ("[the]") ("beginning" 4) ("with" (cont 5)) ("God." (6 unrendered) 7)))
(expect-ok '(status draft) split-literal '(readable ("This one was" 1 2) ("along" 5) ("in the beginning" 3 4) ("with" (cont 5)) ("God." 6 7)))
(expect "holds none of its glosses" '(status draft)
        '(literal ("This" 1) ("[one]") ("was" 2) ("along" 5) ("in" 3) ("[the]") ("beginning" 4) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "no earlier segment aligns word 5" '(status draft)
        '(literal ("This" 1) ("[one]") ("was" 2) ("with" (cont 5)) ("in" 3) ("[the]") ("beginning" 4) ("along" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "both aligns and continues" '(status draft)
        '(literal ("This" 1) ("[one]") ("was" 2) ("with" 5 (cont 5)) ("in" 3) ("[the]") ("beginning" 4) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "which this verse does not have" '(status draft)
        '(literal ("This" 1) ("[one]") ("was" 2) ("with" 5) ("in" 3) ("[the]") ("beginning" 4) ("God." (6 unrendered) 7) ("too" (cont 9))) '(readable "x"))
(expect "Greek word 5 (πρὸς) is not translated" '(status draft)
        '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" (cont 2)) ("God." (6 unrendered) 7)) '(readable "x"))
(let ((uses (verse-uses (verse '(status draft) split-literal) (cdar verses) glosses)))
  (unless (equal? (assv 5 uses) '(5 "πρός" with #t "along … with"))
    (fail "FAIL verse-uses for a split word: ~s~%" (assv 5 uses)))
  (unless (equal? (assv 6 uses) '(6 "ὁ" unrendered #f "God."))
    (fail "FAIL verse-uses for a named sense: ~s~%" (assv 6 uses))))

;; Word numbers and refs.
(expect "aligned twice" '(status draft) '(literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7 7)) '(readable "x"))
(expect "does not have" '(status draft) good-literal '(readable "x") '(note 9 "w"))
(let ((e (check-chapter "t.scm" "john" 1 '((verse 99 (status draft))) verses glosses)))
  (unless (any (lambda (m) (string-contains m "no such verse")) e)
    (fail "FAIL missing verse not reported: ~s~%" e)))

;; Keeping the source's ambiguity.
;; 1. A demonstrative as a personal pronoun or name, in either aligned layer.
(expect "renders the demonstrative οὗτος (word 1, Οὗτος)" '(status draft)
        '(literal ("He" 1) ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "readable segment \"He was\" renders the demonstrative" '(status draft) good-literal
        '(readable ("He was" 1 2) ("in the beginning with God." 3 4 5 6 7)))
(expect-ok '(status draft) '(literal ("This" 1) ("[one]") ("he" (cont 1)) ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
;; 2. A name with no word for it behind the segment.
(expect "says \"God\", but its Greek (ἦν) has no θεός" '(status draft)
        '(literal ("This" 1) ("[one]") ("God was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("him." (6 unrendered) 7)) '(readable "x"))
(expect "says \"Adam\", but its Greek (none: the segment is supplied)" '(status draft)
        '(literal ("This" 1) ("[Adam]") ("was" 2) ("in" 3) ("[the]") ("beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) '(readable "x"))
(expect "readable segment \"Adam was\" says \"Adam\"" '(status draft) good-literal
        '(readable ("Adam was" 1 2) ("in the beginning with God." 3 4 5 6 7)))
(expect-ok '(status draft) good-literal '(readable "This name was in the beginning with God."))
;; 2a. A name spelled like an ordinary gloss word (Ὤν "On", ἐπί "on") is that
;; word when it opens the segment ("On" as a case helper), a name elsewhere.
(let ((g (parse-glosses (append gloss-forms
                                '((lemma "Ὤν" (sense name (gloss "On") (why "w")))
                                  (lemma "ἐπί" (sense on (gloss "on") (why "w"))))))))
  (call-with-values
      (lambda () (check '((status draft) (literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("On beginning" 4) ("with" 5) ("God." (6 unrendered) 7)) (readable "x")) g))
    (lambda (e w) (unless (null? e) (fail "FAIL a segment opening with an ordinary word spelled like a name: ~s~%" e))))
  (call-with-values
      (lambda () (check '((status draft) (literal ("This" 1) ("[one]") ("was" 2) ("in" 3) ("beginning On" 4) ("with" 5) ("God." (6 unrendered) 7)) (readable "x")) g))
    (lambda (e w) (unless (any (lambda (m) (string-contains m "says \"On\"")) e)
                    (fail "FAIL a name not at a segment's start not reported: ~s~%" e)))))
;; 3. A plain readable layer: more names than the literal; a lost demonstrative.
(expect "readable layer says \"God\" 2 times, the literal layer 1" '(status draft) good-literal
        '(readable "This one was in the beginning with God, God."))
(call-with-values (lambda () (check (list '(status draft) good-literal '(readable "He was in the beginning with God.")) glosses))
  (lambda (e w)
    (unless (null? e) (fail "FAIL a lost demonstrative should only warn: ~s~%" e))
    (unless (any (lambda (m) (string-contains m "warning: the literal layer points with \"This\" (Οὗτος, word 1)")) w)
      (fail "FAIL lost demonstrative not warned: ~s~%" w))))

;; Words the readable layer avoids: plain and aligned.
(expect "readable layer uses \"borne\"; write \"moving\"" '(status draft) good-literal '(readable "This one was borne in the beginning."))
(expect "readable layer uses \"borne\"" '(status draft) good-literal '(readable ("This one was Borne" 1 2) ("in the beginning with God." 3 4 5 6 7)))
(expect-ok '(status draft) good-literal '(readable "This one was stubborne in the beginning with God."))

(if (zero? failures)
    (begin (format #t "gsb-translation: all checks passed~%") (exit 0))
    (begin (format #t "gsb-translation: ~a check(s) failed~%" failures) (exit 1)))
