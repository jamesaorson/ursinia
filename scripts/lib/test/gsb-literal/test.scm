;; Copyright (C) 2026
;;
;; Checks for (scripts lib gsb-literal): grammar tags, English inflection, and
;; the rendering rules on small verses with a hand-made lexicon. Run by
;; `make test`.

(use-modules (scripts lib gsb-literal)
             (scripts lib gsb-translation)
             (srfi srfi-1)
             (ice-9 format))

(define failures 0)
(define (check what got want)
  (unless (equal? got want)
    (set! failures (+ failures 1))
    (format #t "FAIL ~a:~%  got  ~s~%  want ~s~%" what got want)))

;; Tags.
(check "verb tag" (tag-field (parse-tag "V-2AAI-3S") 'tense) #\A)
(check "verb person with suffix" (tag-field (parse-tag "V-RAI-2P-ATT") 'person) #\2)
(check "pronoun person" (tag-field (parse-tag "P-1GS") 'person) #\1)
(check "possessive adjective case" (tag-field (parse-tag "S-1PASF") 'case) #\A)
(check "indeclinable name" (tag-field (parse-tag "N-PRI") 'case) #f)

;; English morphology.
(check "past" (map english-past '("make" "carry" "sin" "open")) '("made" "carried" "sinned" "opened"))
(check "ing" (map english-ing '("make" "die" "see")) '("making" "dying" "seeing"))
(check "plural" (map english-plural '("fig tree" "man" "city")) '("fig trees" "men" "cities"))

;; A tiny lexicon and two verses (Genesis 1:3 and 2:7-like).
(define senses
  (gloss-senses
   '((lemma "καί" (sense and (gloss "and") (why "w")))
     (lemma "λέγω" (sense say (gloss "say" "said") (why "w")))
     (lemma "ὁ" (sense the (gloss "the") (why "w")) (sense unrendered (gloss "") (why "w"))
       (sense attributive (gloss "") (why "w")) (sense infinitive (gloss "") (why "w")) (sense absorbed (gloss "") (why "w")))
     (lemma "θεός" (sense god (gloss "God") (why "w")))
     (lemma "γίνομαι" (sense come-to-be (subject "it") (gloss "come to be" "came to be") (why "w")))
     (lemma "φῶς" (sense light (gloss "light") (why "w")))
     (lemma "ἐμφυσάω" (sense breathe (gloss "breathe" "breathed") (why "w")))
     (lemma "εἰς" (sense into (gloss "into") (why "w")))
     (lemma "πρόσωπον" (sense face (gloss "face") (why "w")))
     (lemma "αὐτός" (sense pronoun (gloss "he" "him" "his" "it" "its") (why "w")))
     (lemma "ἄνθρωπος" (sense human (person) (gloss "human") (why "w")))
     (lemma "μετά" (sense with (gloss "with") (why "w")) (sense after (object-case "A") (gloss "after") (why "w")))
     (lemma "γεννάω" (sense beget (gloss "beget" "begetting") (why "w")))
     (lemma "Σήθ" (sense name (gloss "Seth") (why "w")))
     (lemma "ἡμέρα" (sense day (gloss "day") (why "w")))
     (lemma "ἁγιάζω" (sense sanctify (gloss "sanctify") (why "w"))))))

(define (row n word post lemma tag) (list n "" word post lemma "" "" '()))
(define forms
  (index-forms-rows
   '(("καὶ" "καί" "CONJ") ("εἶπεν" "λέγω" "V-2AAI-3S") ("ὁ" "ὁ" "T-NSM") ("θεός" "θεός" "N-NSM")
     ("Γενηθήτω" "γίνομαι" "V-AOM-3S") ("φῶς" "φῶς" "N-NSN") ("ἐγένετο" "γίνομαι" "V-2ADI-3S")
     ("ἐνεφύσησεν" "ἐμφυσάω" "V-AAI-3S") ("εἰς" "εἰς" "PREP") ("τὸ" "ὁ" "T-ASN") ("πρόσωπον" "πρόσωπον" "N-ASN")
     ("αὐτοῦ" "αὐτός" "P-GSM") ("τὸν" "ὁ" "T-ASM") ("ἄνθρωπον" "ἄνθρωπος" "N-ASM")
     ("μετὰ" "μετά" "PREP") ("γεννῆσαι" "γεννάω" "V-AAN") ("αὐτὸν" "αὐτός" "P-ASM") ("Σήθ" "Σήθ" "N-PRI")
     ("τὴν" "ὁ" "T-ASF") ("ἡμέραν" "ἡμέρα" "N-ASF") ("ἁγιάζειν" "ἁγιάζω" "V-PAN") ("αὐτήν" "αὐτός" "P-ASF"))))
(define env (make-env forms (make-hash-table) senses '() (make-hash-table) (make-hash-table)))

(define (english ref words)
  (call-with-values (lambda () (render-verse env ref words #t))
    (lambda (segs stop?) (string-join (map car segs) " "))))

;; Subject before the verb; "Let ... come to be" around the subject; speech comma.
(check "Genesis 1:3"
       (english "gen.1.3" (list (row 1 "καὶ" "" "καί" "") (row 2 "εἶπεν" "" "λέγω" "") (row 3 "ὁ" "" "ὁ" "")
                                (row 4 "θεός" "" "θεός" "") (row 5 "Γενηθήτω" "" "γίνομαι" "") (row 6 "φῶς" "·" "φῶς" "")
                                (row 7 "καὶ" "" "καί" "") (row 8 "ἐγένετο" "" "γίνομαι" "") (row 9 "φῶς" "." "φῶς" "")))
       "And God said, Let light come to be; and light came to be.")

;; Rule 16a: an unstated third singular subject stays "he/she/it"; a verb
;; joined by καί to the verb before has none; αὐτοῦ (masculine or neuter)
;; is "his" when its nearest agreeing noun is a person, "its" for a thing,
;; "his/its" when there is none.
(check "open subject, καί-joined verb"
       (english "gen.2.7" (list (row 1 "καὶ" "" "καί" "") (row 2 "εἶπεν" "" "λέγω" "") (row 3 "τὸν" "" "ὁ" "")
                                (row 4 "ἄνθρωπον" "" "ἄνθρωπος" "") (row 5 "καὶ" "" "καί" "") (row 6 "ἐνεφύσησεν" "" "ἐμφυσάω" "")
                                (row 7 "εἰς" "" "εἰς" "") (row 8 "τὸ" "" "ὁ" "") (row 9 "πρόσωπον" "" "πρόσωπον" "")
                                (row 10 "αὐτοῦ" "." "αὐτός" "")))
       "And he/she/it said the human and breathed into his face.")
(check "possessive with a person as nearest agreeing noun"
       (english "gen.2.7" (list (row 1 "εἶπεν" "" "λέγω" "") (row 2 "τὸν" "" "ὁ" "") (row 3 "ἄνθρωπον" "" "ἄνθρωπος" "")
                                (row 4 "εἰς" "" "εἰς" "") (row 5 "τὸ" "" "ὁ" "") (row 6 "πρόσωπον" "" "πρόσωπον" "")
                                (row 7 "αὐτοῦ" "." "αὐτός" "")))
       "He/she/it said the human into his face.")
(check "masculine/neuter pronoun left open"
       (english "gen.2.7" (list (row 1 "ἐνεφύσησεν" "" "ἐμφυσάω" "") (row 2 "εἰς" "" "εἰς" "") (row 3 "τὸ" "" "ὁ" "")
                                (row 4 "πρόσωπον" "" "πρόσωπον" "") (row 5 "αὐτοῦ" "." "αὐτός" "")))
       "He/she/it breathed into his/its face.")

;; Preposition + article + infinitive + accusative subject: a possessive gerund.
(check "articular infinitive with its subject"
       (english "gen.5.4" (list (row 1 "μετὰ" "" "μετά" "") (row 2 "τὸ" "" "ὁ" "") (row 3 "γεννῆσαι" "" "γεννάω" "")
                                (row 4 "αὐτὸν" "" "αὐτός" "") (row 5 "τὸν" "" "ὁ" "") (row 6 "Σήθ" "." "Σήθ" "")))
       "After his begetting Seth.")
;; A gendered pronoun whose nearest agreeing noun is a thing is "it".
(check "feminine pronoun for a thing"
       (english "exod.20.8" (list (row 1 "τὴν" "" "ὁ" "") (row 2 "ἡμέραν" "" "ἡμέρα" "") (row 3 "ἁγιάζειν" "" "ἁγιάζω" "")
                                  (row 4 "αὐτήν" "." "αὐτός" "")))
       "The day to sanctify it.")

;; The segments keep every Greek word, in translation-file form.
(let ((sexp (call-with-values (lambda () (render-verse env "gen.1.3"
                                                      (list (row 1 "Γενηθήτω" "" "γίνομαι" "") (row 2 "φῶς" "." "φῶς" ""))
                                                      #t))
              (lambda (segs _) (segments->sexp env segs (make-hash-table))))))
  (check "segments" sexp '(("Let" (1 come-to-be "γίνομαι")) ("light" (2 light "φῶς")) ("come to be." (cont 1)))))

(if (zero? failures)
    (format #t "gsb-literal: all checks pass~%")
    (begin (format #t "gsb-literal: ~a check(s) failed~%" failures) (exit 1)))
