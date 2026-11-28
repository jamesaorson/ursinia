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
;; consonant doubling by rule (one syllable consonant-vowel-consonant) and list
(check "ing doubling" (map english-ing '("blot" "run" "beget" "open" "visit" "snow" "fix" "rain"))
       '("blotting" "running" "begetting" "opening" "visiting" "snowing" "fixing" "raining"))
(check "past doubling" (map english-past '("blot" "beg" "prosper")) '("blotted" "begged" "prospered"))
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
;; joined by καί to the verb before (same person and number) has none;
;; αὐτοῦ (masculine or neuter)
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

;; (verb "come back" "came back" ...) and (verb "come back" "came" ...) give
;; the particle once.
(for-each
 (lambda (v)
   (let* ((s (gloss-senses `((lemma "ἀναστρέφω" (sense return ,v (gloss "come back" "came back") (why "w"))))))
          (f (index-forms-rows '(("ἀνέστρεψεν" "ἀναστρέφω" "V-AAI-3S"))))
          (e (make-env f (make-hash-table) s '() (make-hash-table) (make-hash-table))))
     (check (format #f "particle once ~s" v)
            (call-with-values (lambda () (render-verse e "gen.8.9" (list (row 1 "ἀνέστρεψεν" "." "ἀναστρέφω" "")) #t))
              (lambda (segs _) (string-join (map car segs) " ")))
            "He/she/it came back.")))
 '((verb "come back" "came back" "come back") (verb "come back" "came" "come")))

;;; Real verses, rendered from the repository's data (form analyses,
;;; concordance, phrases) with NO overrides or pinned verses, so each check is
;;; the rules' own output. Expected English decided from the Greek in
;;; gsb/greek/01-gen.tsv.
(define real-env
  (call-with-values load-literal-env
    (lambda (e problems)
      (make-env (env-forms e) (env-nt e) (env-senses e) (env-phrases e) (make-hash-table) (make-hash-table)))))
(define gen-verses (read-greek-table "gsb/greek/01-gen.tsv"))
(define (gen ref)
  (call-with-values (lambda () (render-verse real-env ref (assoc-ref gen-verses ref) #t))
    (lambda (segs stop?) (string-join (map car segs) " "))))
(define (has ref . parts)
  (let ((text (gen ref)))
    (for-each (lambda (p) (check (format #f "~a has ~s" ref p) (and (string-contains text p) #t) #t)) parts)))
(define (lacks ref . parts)
  (let ((text (gen ref)))
    (for-each (lambda (p) (check (format #f "~a lacks ~s (in ~s)" ref p text) (string-contains text p) #f)) parts)))

;; A1. μή opening a question expects "no": a plain yes/no question, not a negation.
(has "gen.18.14" "Is utterance impossible beside God?")
(has "gen.18.17" "Shall I hide from Abraham")
(has "gen.4.9" "am I guard of my brother?")
(has "gen.27.38" "Is one blessing to you, father?")
;; A2. Prohibitions: μή + second person subjunctive, no subject pronoun.
(has "gen.18.3" "do not pass by your servant")
(lacks "gen.18.3" "you do not pass")
(has "gen.19.7" "do not do evil")
(has "gen.19.17" "do not look around" "nor stand")
(has "gen.22.12" "Do not cast your hand upon the lad")
(has "gen.26.2" "Do not go down into Egypt")
(has "gen.3.1" "You will not eat at all")   ; οὐ μή is not a prohibition
;; μή + first/third person subjunctive, μή ποτε: "lest".
(has "gen.19.19" "lest the bad overtake me and I die")
(has "gen.20.2" "lest ever the men of the city kill him")
;; A3. The whole subject phrase moves, or nothing; never across a clause.
(has "gen.27.19" "And Jacob his son said to his father")
(has "gen.20.2" "But Abimelech king of Gerar sent and took Sarah")
(has "gen.21.22" "Abimelech and Ahuzzath his groomsman and Phicol the commander-in-chief of his power said to Abraham")
(has "gen.24.36" "And Sarah the woman of my")
(has "gen.24.12" "said, Lord the God of")          ; vocative not moved, no [the]
(has "gen.27.35" "Your brother having come with deceit took your blessing")
(has "gen.24.65" "But the servant said, This is my")
(lacks "gen.28.20" "I preserve")
(has "gen.9.22" "And Ham the father of Canaan saw the nakedness of his father")
(has "gen.9.23" "And Shem and Japheth having taken the garment")
(has "gen.7.21" "And every flesh moving upon the earth of the birds and the livestock and the beasts died")
(has "gen.10.10" "beginning of his/its kingdom came to be Babylon")
(has "gen.25.11" "God blessed Isaac his son")
(has "gen.26.5" "Abraham your father obeyed")
(has "gen.12.7" "Abram built there altar")
(has "gen.21.20" "but he came to be archer")       ; a person predicate gives the gender
(has "gen.20.7" "that he is prophet")
(has "gen.12.18" "that she is your woman")
(has "gen.20.9" "What [is] this you made to us?")
(has "gen.19.38" "But also the younger bore son")
(has "gen.8.9" "And the dove not having found rest")
(has "gen.12.11" "I know that")
(has "gen.19.13" "That we destroy this place")
(has "gen.22.12" "that you fear God")
(has "gen.4.26" "son came to be")                 ; a dative possessor: the person is the subject
(lacks "gen.22.1" "Abraham said")                 ; Ἀβραὰμ Ἀβραάμ is a call
(has "gen.27.1" "and called Esau his son")        ; undecidable: Greek order, no false actor
(has "gen.27.18" "who are you, child?")
;; A4. Subjects of articular infinitives: possessive gerunds.
(has "gen.19.16" "in [the] Lord's sparing him")
(has "gen.19.29" "in [the] Lord's rubbing out all the cities" "in [the] Lord's overturning the cities")
(has "gen.13.14" "after Lot's being separated from him")
(has "gen.16.3" "of Abram's dwelling")
(has "gen.27.1" "after Isaac's growing old")
(has "gen.8.7" "until the water's being dried up from the earth")
(has "gen.19.19" "of my soul's living")
(has "gen.20.6" "of your not sinning into me")
(has "gen.28.15" "until my making all")
(has "gen.24.33" "until my speaking my utterances")
(has "gen.27.33" "before your going in")
(has "gen.11.2" "in their moving")
(has "gen.28.6" "in blessing him")                ; a transitive infinitive's pronoun is its object
;; A5. Genitive absolutes.
(has "gen.18.1" "he being seated upon the door")
(has "gen.24.30" "he having stood upon the camels")
(has "gen.25.6" "he further living")
;; B. Mechanics.
(lacks "gen.13.8" "Let  not")

(if (zero? failures)
    (format #t "gsb-literal: all checks pass~%")
    (begin (format #t "gsb-literal: ~a check(s) failed~%" failures) (exit 1)))
