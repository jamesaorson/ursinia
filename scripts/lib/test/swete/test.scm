;; Copyright (C) 2026
;;
;; Checks for (scripts lib swete): page parsing, verse tables in the common
;; numbering (across page breaks), book validation, hOCR main-text extraction
;; and collation classes. Run by `make test`.

(use-modules (scripts lib swete)
             (ice-9 match)
             (srfi srfi-1)
             (ice-9 format))

(define failures 0)

(define-syntax-rule (check expr expected)
  (let ((actual expr))
    (unless (equal? actual expected)
      (set! failures (+ failures 1))
      (format #t "FAIL ~s~%  expected ~s~%  actual   ~s~%" 'expr expected actual))))

(define (page leaf text) (cons leaf (parse-page text)))

;;; Page files

(define p38 (parse-page "# theoldtestamenti00unknuoft leaf 0038 (printed page 6)\n# box 280 2700 260 2010\n# done 2026-11-26 swete-2\nfirst line\n\nsecond line\n"))
(check (page-header p38 "scan") '("theoldtestamenti00unknuoft" 38 "6"))
(check (page-header p38 "box") '("280" "2700" "260" "2010"))
(check (page-lines p38) '((1 . "first line") (2 . "second line")))

;;; Verse tables: two pages by different hands, a verse and a hyphenated word
;;; running across the break, Swete's 3:1 = common 2:25 + 3:1.

(define pages
  (list (page 36 "# s leaf 0036\n{C2}{24}ἕνεκεν τούτου¶ καὶ\nἔσονται. {C3}{1}{=2:25}καὶ ἦσαν οἱ δύο γυ-\n")
        (page 37 "# s leaf 0037\nμνοί.\n{P}{=3:1}Ὁ δὲ §ὄφις [ἦν]. {2}καὶ\nεἶπεν\n")))

(call-with-values (lambda () (book-verses pages))
  (lambda (rows problems)
    (check rows '((2 24 "ἕνεκεν τούτου καὶ ἔσονται.")
                  (2 25 "καὶ ἦσαν οἱ δύο γυμνοί.")
                  (3 1 "Ὁ δὲ ὄφις [ἦν].")
                  (3 2 "καὶ εἶπεν")))
    (check problems '())))

;; A Swete verse split by the common numbering the other way round (two Swete
;; verses, one common verse) comes out as one row.
(call-with-values (lambda () (book-verses (list (page 1 "{C1}{1}α β {2}{=1:1}γ δ {3}{=1:2}ε"))))
  (lambda (rows problems) (check rows '((1 1 "α β γ δ") (1 2 "ε")))))

;;; Validation

(define (messages pages opening end)
  "The failures only, as (leaf line fail)."
  (filter-map (lambda (p) (and (eq? (third p) 'fail) (list (first p) (second p) (third p))))
              (book-problems pages opening end 1)))

(check (messages (list (page 33 "# s leaf 0033\n# box 1 2 3 4\n{C1}{1}α. {2}β. {4}γ.\n")) 33 #f)
       '((33 1 fail)))                                  ; verse 4 after 2
(check (messages (list (page 33 "# s leaf 0033\n# box 1 2 3 4\n{C1}{1}α [β. {2}γ.\n")) 33 33)
       '((33 1 fail)))                                  ; [ never closed at the book's end
(check (messages (list (page 33 "# s leaf 0033\n# box 1 2 3 4\n{C1}{1}α [β.\n")
                       (page 34 "# s leaf 0034\n# box 1 2 3 4\nγ] δ.\n"))
                 33 #f)
       '())                                             ; bracket spans the page break
(check (messages (list (page 33 "# s leaf 0033\n# box 1 2 3 4\n{C1}{1}Kal θεός.\n")) 33 #f)
       '((33 1 fail)))                                  ; Latin letters
(check (messages (list (page 33 "# s leaf 0033\n# box 1 2 3 4\n{C1}{1}θεός.\n")) 33 #f)
       '((33 1 fail)))                                  ; not NFC
(check (messages (list (page 33 "# s leaf 0033\n# box 1 2 3 4\n{C1}{1}α. {2}β. {3}{=1:1}γ.\n{x}\n")) 33 #f)
       '((33 1 fail) (33 2 fail)))                      ; common 1:1 after 1:2; unknown marker {x}
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\nμέσον. {9}α.\n")) 33 #f)
       '())                                             ; a run that starts mid-book is not judged on its opening
(check (messages (list (page 33 "# s leaf 0034\n{C1}{1}α.\n")) 33 #f)
       '((33 0 fail) (33 0 fail)))                      ; wrong leaf in header, no box

;;; hOCR main text

(define hocr
  (string-append
   "<div class='ocr_page' title='bbox 0 0 2000 3000'>"
   ;; running head, above the box
   "<span class='ocr_line' title=\"bbox 200 100 1800 150\"><span class='ocrx_word' title='bbox 200 100 400 150'>ΓΕΝΕΣΙΣ</span></span>"
   ;; accent-row junk overlapping the next line
   "<span class='ocr_line' title=\"bbox 200 300 1800 330\"><span class='ocrx_word' title='bbox 200 300 260 330'>᾿ς</span><span class='ocrx_word' title='bbox 300 300 360 330'>« ’</span></span>"
   "<span class='ocr_line' title=\"bbox 200 300 1800 370\">"
   "<span class='ocrx_word' title='bbox 200 310 400 370'>καὶ</span>"
   "<span class='ocrx_word' title='bbox 420 310 700 370'>&#39;Αδὰμ</span>"
   "<span class='ocrx_word' title='bbox 720 310 900 370'><strong>εἶπεν</strong></span>"
   ;; a margin number right of the box
   "<span class='ocrx_word' title='bbox 1900 310 1950 370'>17</span></span>"
   "<span class='ocr_line' title=\"bbox 200 400 1800 470\">"
   "<span class='ocrx_word' title='bbox 200 410 500 470'>Τενηθήτω</span>"
   "<span class='ocrx_word' title='bbox 520 410 700 470'>φῶς:</span></span>"
   "</div>"))

(define lines (main-text-lines (hocr-lines hocr) '(250 3000 150 1850)))
(check (map (lambda (l) (map fifth (third l))) lines) '(("καὶ" "'Αδὰμ" "εἶπεν") ("Τενηθήτω" "φῶς:")))
(check (ocr-normalize "᾿Αδὰμ") "Ἀδὰμ")
(check (ocr-normalize "'Αδὰμ") "Ἀδὰμ")
(check (ocr-normalize "καθ’") "καθ᾽")

;;; Collation

(define ours (parse-page "{C1}{3}καὶ Ἀδὰμ εἶπεν\nΓενηθήτω φῶς·\n"))
(define rows (collate (page-tokens ours) (ocr-tokens lines) (ocr-tokens lines)))
(define (row c) (find (lambda (r) (string=? (assq-ref r 'c) c)) rows))
(check (assq-ref (row "Ἀδὰμ") 'hazards) '(H1))               ; breathing on a capital: always zoom
(check (assq-ref (row "Ἀδὰμ") 'basis) #f)
(check (assq-ref (row "Γενηθήτω") 'class-a) 'OPEN)           ; Γ read as Τ
(check (assq-ref (row "Γενηθήτω") 'basis) #f)                 ; both OCRs wrong the same way: zoom
(check (assq-ref (row "φῶς·") 'class-b) 'R2)                   ; ano teleia read as a colon
(check (and (assq-ref (row "φῶς·") 'basis) #t) #t)
(check (assq-ref (row "Ἀδὰμ") 'word) '(420 310 700 370 "'Αδὰμ"))

;; Classes one by one: the OCR reading against ours.
(define (class-of c o at-verse?)
  (let* ((toks (list (list o '(0 0 10 10 "x") 0)))
         (r (collate (list (list c 1 at-verse?)) toks toks)))
    (and (pair? r) (assq-ref (car r) 'class-a))))
(check (class-of "καὶ" "3καὶ" #t) 'R1)                        ; verse superscript fused
(check (class-of "καὶ" "3καὶ" #f) 'OPEN)                      ; ...only where a verse starts
(check (class-of "πετόμεν[α]" "πετόμενα" #f) 'R4)
(check (class-of "καὶ" "Kal" #f) 'R5)
(check (class-of "ὁ" "ὃ" #f) 'DIA)
(check (class-of "ἦσαν" "ησαν" #f) 'DROP)
(check (class-of "καὶ" "καὶ" #f) #f)                          ; agreement: no row

;;; Verse numbering the Septuagint way (Gen 35:16-22, Gen 31:44-54)

;; Transposed verses: an explicit common reference may go backwards; the
;; table keeps the printed order.
(define p99 (page 33 "# s leaf 0033\n# box 1 2 3 4\n{C1}{15}α.\n{P}{16}{=1:21}β. {=1:16}γ. {17}δ. {18}ε. {19}ζ. {20}η. {21}{=1:22}θ. {22}ι.\n"))
(call-with-values (lambda () (book-verses (list p99)))
  (lambda (rows problems)
    (check (map (lambda (r) (list (first r) (second r))) rows)
           '((1 15) (1 21) (1 16) (1 17) (1 18) (1 19) (1 20) (1 22)))
    (check (third (last rows)) "θ. ι.")))                ; Swete's 21 and 22 are both common 22
(check (messages (list p99) 33 #f) '((33 1 fail)))        ; only: the opening {C1} does not start at {1}

;; Half verses and a printed skip in Swete's own numbers.
(define p92 (page 40 "# s leaf 0040\n# box 1 2 3 4\n{46}α. {=31:48a}β. {47}γ. {48}{=31:51}δ. {=31:52a}ε. {=31:48b}ζ.\n{49}η. {50}{=31:50a}θ. {52!}{=31:52b}ι. {53}κ.\n"))
(check (messages (list (page 39 "# s leaf 0039\n# box 1 2 3 4\n# done 2026-11-27 swete-2\n{C31}{1}ξ.\n") p92) #f #f) '((40 1 fail)))  ; 1 -> 46 across the leaves
(check (messages (list p92) #f #f) '())
(call-with-values (lambda () (book-verses (list (page 39 "# s\n{C31}{45}x.\n") p92)))
  (lambda (rows problems)
    (check (map second rows) '(45 46 "48a" 47 51 "52a" "48b" 49 "50a" "52b" 53))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{49}α. {50}β. {52}γ.\n")) #f #f)
       '((40 1 fail)))                                   ; an unmarked skip still fails
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{49}α. {50!}β.\n")) #f #f)
       '((40 1 fail)))                                   ; {n!} where nothing is skipped
;; A chapter that opens on a later number as printed (1 Kgdms 18 opens at 6).
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C17}{1}α. {C18}{6!}β. {7}γ.\n")) #f #f) '())
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C17}{1}α. {C18}{6}β.\n")) #f #f)
       '((40 1 fail)))                                   ; unmarked, still fails
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C17}{1}α. {C18}{1!}β.\n")) #f #f)
       '((40 1 fail)))                                   ; {1!} opening a chapter
;; Swete's own numbers printed out of sequence (Num 6:23-27, 10:33-36): each
;; out-of-place number is marked; the table keeps the printed order, no warnings.
(check (book-problems (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C10}{1}α. {2}β. {3}γ. {5!}δ. {6}ε. {4!}ζ. {C11}{1}η.\n")) #f #f 1)
       '())                                              ; no failures and no warnings
(call-with-values (lambda () (book-verses (list (page 40 "{C10}{33}α. {35!}β. {36}γ. {34!}δ. {C11}{1}ε."))))
  (lambda (rows problems) (check (map second rows) '(33 35 36 34 1))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{23}α. {27!}β. {24}γ.\n")) #f #f)
       '((40 1 fail)))                                   ; the number after an early one is marked too
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C10}{1}α. {2}β. {3}γ. {2!}{=10:9}δ.\n")) #f #f)
       '((40 1 fail)))                                   ; a Swete number twice in a chapter
;; ... unless marked as printed a second time (2 Kgdms 23: 29, 31, ... 39, 30, 31)
(check (book-problems (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C23}{1}ω. {29!}α. {31!}{=23:31a}β. {32}γ. {30!}δ. {31!!}{=23:31b}ε. {C24}{1}ζ.\n")) #f #f 1)
       '())
(call-with-values (lambda () (book-verses (list (page 40 "{C23}{29}α. {31!}{=23:31a}β. {32}γ. {30!}δ. {31!!}{=23:31b}ε."))))
  (lambda (rows problems) (check (map second rows) '(29 "31a" 32 30 "31b"))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C10}{1}α. {2}β. {4!!}γ.\n")) #f #f)
       '((40 1 fail)))                                   ; {n!!} for a number not printed before
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C31}{1}α. {2}{=31:5}β. {3}γ. {4}{=31:5}δ.\n")) #f #f)
       '((40 1 fail)))                                   ; the same common verse twice
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C31}{1}α. {2}{=31:1a}β.\n")) #f #f)
       '((40 1 fail)))                                   ; a whole verse and a half of it
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C31}{1}α. {=31:1}β.\n")) #f #f)
       '())                                              ; the same reference running on is one row

;; Psalm titles {T}: the unnumbered superscription is verse 1; Swete's first
;; number after it is 2, or 1 when the title runs on into his verse 1. Stich
;; depths {S} {S1} {S2} are poetry lines.
(define pt (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C1}{S}{1}α,\n{S1}β. {C2}{T}γ\n{T}δ.\n{S}{2}ε\n{S2}ζ. {C3}{T}η. {S}{1}θ. {2}ι.\n"))
(check (book-problems (list pt) 40 #f 1) '())
(call-with-values (lambda () (book-verses (list pt)))
  (lambda (rows problems)
    (check rows '((1 1 "α, β.") (2 1 "γ δ.") (2 2 "ε ζ.") (3 1 "η. θ.") (3 2 "ι.")))))
(call-with-values (lambda () (book-verses (list (page 40 "{C2}{T}γ-\n{T}δ. {2}ε"))))
  (lambda (rows problems) (check rows '((2 1 "γδ.") (2 2 "ε")))))   ; a hyphen across title lines
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C2}{1}α. {T}β.\n")) #f #f)
       '((40 1 fail)))                                   ; a title after a verse
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C2}{T}α {2}β\n{S}γ.\n{T}δ.\n")) #f #f)
       '((40 3 fail)))                                   ; ... after a verse line
;; Swete's {2} inside a title's first line, more title lines after it (Ps 51).
(define pt2 (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C51}{T}α, {2}β\n{T}γ.\n{S}δ\n{S1}ε. {3}ζ.\n"))
(check (book-problems (list pt2) #f #f 1) '())
(call-with-values (lambda () (book-verses (list pt2)))
  (lambda (rows problems) (check rows '((51 1 "α,") (51 2 "β γ. δ ε.") (51 3 "ζ.")))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C2}{T}α. {3}β.\n")) #f #f)
       '((40 1 fail)))                                   ; 3 after a title, unmarked

;; Swete's own lettered verses (Josh 21:42a-d; 24: 28, 31, 29, 30, 30a, 32):
;; verses of their own after his number, not halves of it.
(define pj (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C24}{1}α. {4!}β. {2!}γ. {3}δ. {3a}ε. {5!}ζ. {6}η. {6a}θ. {6b}ι.\n"))
(check (book-problems (list pj) #f #f 1) '())             ; no failures and no warnings
(call-with-values (lambda () (book-verses (list pj)))
  (lambda (rows problems) (check (map second rows) '(1 4 2 3 "3a" 5 6 "6a" "6b"))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C21}{1}α. {2}β. {2a}γ. {2b}δ. {3}ε.\n")) #f #f)
       '())                                              ; 3 runs on from 2
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C21}{1}α. {2a}β.\n")) #f #f)
       '((40 1 fail)))                                   ; 2a without 2 before it
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C21}{1}α. {2}β. {2a}γ. {2a}δ.\n")) #f #f)
       '((40 1 fail)))                                   ; the same letter twice

;; Lettered sections (Esther's additions A-F): A before 1:1, B inside 3, the
;; interrupted chapter resumed by its reprinted numeral ('III 14').
(define pe (page 40 "# s leaf 0040\n# box 1 2 3 4\n{CA}{1}α. {2}β. {C1}{1}γ. {C2}{1}δ. {C3}{1}ε. {2}ζ. {CB}{1}η. {2}θ. {C3}{3}ι. {C4}{1}κ. {CC}{1}λ. {CD}{1}μ. {C5}{3!}ν.\n"))
(check (book-problems (list pe) 40 #f 1) '())             ; no failures and no warnings
(call-with-values (lambda () (book-verses (list pe)))
  (lambda (rows problems)
    (check (map (lambda (r) (take r 2)) rows)
           '(("A" 1) ("A" 2) (1 1) (2 1) (3 1) (3 2) ("B" 1) ("B" 2) (3 3) (4 1) ("C" 1) ("D" 1) (5 3)))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{CA}{1}α. {C1}{1}β. {CC}{1}γ.\n")) 40 #f)
       '((40 1 fail)))                                   ; C without B
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C1}{1}α. {2}β. {CA}{1}γ. {C1}{4}δ.\n")) 40 #f)
       '((40 1 fail)))                                   ; a resumed chapter runs on from its last verse
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C1}{1}α. {CA}{1}γ. {C3}{1}δ.\n")) 40 #f)
       '((40 1 fail)))                                   ; nor does a section skip a chapter
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{CA}{1}α. {3}β.\n")) 40 #f)
       '((40 1 fail)))                                   ; Swete's numbers inside a section run on
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{2}α. {3}β. {CD}{1}γ. {C5}{3!}δ.\n")) #f #f)
       '())                                              ; a run starting mid-book: letter and chapter unknown
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\nα. {C8}{13}β. {14}γ.\n")) #f #f)
       '())                                              ; ... and may be resuming a chapter after a section
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C8}{13}β.\n")) #f #f)
       '((40 1 fail)))                                   ; but a chapter with no text before it opens at 1

;; Combined common numbers (Exod 37:4-5, 36:34,36): one row, each verse claimed.
(call-with-values (lambda () (book-verses (list (page 40 "{C38}{1}{=37:4-5}α. {2}{=36:34,36}β. {3}{=37:6}γ."))))
  (lambda (rows problems) (check (map second rows) '("4-5" "34,36" 6))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C38}{1}{=37:4-5}α. {2}{=36:34,36}β. {3}{=36:35}γ.\n")) #f #f)
       '())                                              ; 36:35 is not in 34,36
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C38}{1}{=37:4-5}α. {2}{=37:5}β.\n")) #f #f)
       '((40 1 fail)))                                   ; 37:5 is inside 37:4-5
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C38}{1}{=36:36}α. {2}{=36:34,36}β.\n")) #f #f)
       '((40 1 fail)))                                   ; 36:36 is in 36:34,36
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C38}{1}{=37:5-4}α.\n")) #f #f)
       '((40 1 fail)))                                   ; a range must ascend
;; A number Swete prints twice: our a/b halves, also inside a list (Exod 36:36).
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C39}{1}{=39:1a}α. {2}{=38:2}β. {3}{=39:1b}γ.\n")) #f #f)
       '())
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C38}{1}{=36:36a}α. {2}{=36:34,36b}β.\n")) #f #f)
       '())
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C38}{1}{=36:36a}α. {2}{=36:34,36a}β.\n")) #f #f)
       '((40 1 fail)))
;; A combined number whose first verse is a half (3 Kgdms (17 b-19) after
;; (17) at 4:33): 9:17b-19 claims 17b, 18, 19; 9:17a stays free, 9:18 clashes.
(call-with-values (lambda () (book-verses (list (page 40 "{C10}{1}{=9:17a}α. {2}{=9:17b-19}β. {3}{=9:20}γ."))))
  (lambda (rows problems) (check (map second rows) '("17a" "17b-19" 20))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C10}{1}{=9:17a}α. {2}{=9:17b-19}β.\n")) #f #f)
       '())
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C10}{1}{=9:17}α. {2}{=9:17b-19}β.\n")) #f #f)
       '((40 1 fail)))                                   ; whole 17 and its half
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C10}{1}{=9:17b-19}α. {2}{=9:18}β.\n")) #f #f)
       '((40 1 fail)))                                   ; 18 is inside 17b-19
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C10}{1}{=9:17b,19}α. {2}{=9:18}β.\n")) #f #f)
       '())

;; A Swete verse with no {=c:v} landing in another chapter than the common
;; verse before it warns (run it on); the next chapter's verse 1 does not.
(define (warnings pages) (filter-map (lambda (p) (and (eq? (third p) 'warn) (second p))) (book-problems pages #f #f 1)))
(check (warnings (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C36}{25}{=39:17}α.\n{26}β.\n"))) '(2))
(check (warnings (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C36}{25}{=39:17}α.\n{26}{=39:17}β.\n"))) '())
(check (warnings (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C8}{32}{=8:28}α.\n{C9}{1}β.\n"))) '())

;; An unfinished leaf ends the run: no chapter is inferred past it (Lev
;; leaves 262-266), and the next leaf says its checks were skipped.
(define (fail-text pages) (filter-map (lambda (p) (and (eq? (third p) 'fail) (fourth p))) (book-problems pages #f #f 1)))
(define (problem-text pages) (map (lambda (p) (list (first p) (third p) (fourth p))) (book-problems pages #f #f 1)))
(check (problem-text (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C1}{1}α.\n")
                           (page 41 "# s leaf 0041\n# box 1 2 3 4\n{5}β.\n")))
       '((41 warn "order and duplicate checks against earlier leaves skipped: leaf 40 is unfinished (they run once it is done)")))
(check (problem-text (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n# done 2026-11-27 swete-2\n{C1}{1}α. {2}β.\n")
                           (page 41 "# s leaf 0041\n# box 1 2 3 4\nβ.\n")      ; partial: its {C2}{1} not yet written
                           (page 42 "# s leaf 0042\n# box 1 2 3 4\n# done 2026-11-27 swete-2\n{2}γ.\n")))
       '((42 warn "order and duplicate checks against earlier leaves skipped: leaf 41 is unfinished (they run once it is done)")))
(check (length (fail-text (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n# done 2026-11-27 swete-2\n{C1}{1}α.\n")
                                (page 41 "# s leaf 0041\n# box 1 2 3 4\n{5}β.\n"))))
       1)                                               ; a done leaf before: still judged

;; Decision rows: the revision token decide checks.
(define dr (list (list "lev" "s" "40" "3" "ὁ" "ὁ" "ὃ" "ὃ" "TODO zoom") (list "lev" "s" "40" "5" "Τῇ" "Τῇ" "Γῇ" "Γῇ" "TODO zoom")))
(check (rows-revision dr) (rows-revision (list (append (take (car dr) 8) '("image: rough")) (cadr dr))))  ; decide: same
(check (rows-revision dr) (rows-revision (append dr (list (list "lev" "s" "40" "7" "-" "-" "ω" "ω" "ambiguous")))))  ; flag: same
(check (equal? (rows-revision dr) (rows-revision (reverse dr))) #f)                           ; renumbered: differs

;; Printed line -> OCR line: the OCR split our line 2 and lost line 1's last word.
(check (ocr-line-of (page-tokens (parse-page "α β γ\nδ ε ζ η\nθ"))
                    (map (lambda (t k) (list t #f k)) '("α" "β" "δ" "ε" "ζ" "η" "θ") '(0 0 1 1 1 2 3))
                    2)
       1)
(check (ocr-line-of (page-tokens (parse-page "α\nβ")) '() 1) #f)

;; Numerals: the keraia is ʹ (U+02B9) right after the letters, nothing else.
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C1}{1}ἦσαν ιβʹ πηγαί.\n")) #f #f) '())
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C1}{1}κ' στύλους ιβ΄ ʹα.\n")) #f #f)
       '((40 1 fail)))                                   ; ASCII apostrophe, U+0384, a keraia after a space
(check (map first (page-tokens (parse-page "{C1}{1}ἦσαν ιβʹ, πηγαί"))) '("ἦσαν" "ιβʹ," "πηγαί"))

;;; English chapter division (versification.tsv): Hebrew 7:26-29 = English
;;; 8:1-4, Hebrew 8:1-28 = English 8:5-32; other rows and the text untouched.
(check (english-numbering '((7 25 "a") (7 26 "b") (7 29 "c") (8 1 "d") (8 "2a" "e") (8 "3-4" "f") (9 1 "g"))
                          '((7 26 29 8 1) (8 1 28 8 5)))
       '((7 25 "a") (8 1 "b") (8 4 "c") (8 5 "d") (8 "6a" "e") (8 "7-8" "f") (9 1 "g")))
;; Hebrew Num 25:19 is the start of English 26:1: the two rows join.
(check (english-numbering '((25 18 "a") (25 19 "b") (26 1 "c") (26 2 "d")) '((25 19 19 26 1)))
       '((25 18 "a") (26 1 "b c") (26 2 "d")))

;;; Decision rows: collate's reconciliation

(define (drow line a b c chosen basis) (list "gen" "s" "40" line a b c chosen basis))
(define (crow line a b c) `((line . ,line) (a . ,a) (b . ,b) (c . ,c)))
(call-with-values
    (lambda ()
      (reconcile (list (crow 3 "ὁ" "ὁ" "ὃ")           ; same line and readings: kept
                       (crow 5 "Τῇ" "Τῇ" "Γῇ")        ; box changed, new readings: carried over
                       (crow 9 "ἄγε" "ἀγε" "ἄγε"))    ; new
                 (list (drow "3" "ὁ" "ὁ" "ὃ" "ὃ" "image: rough breathing")
                       (drow "5" "Τη" "Τη" "Γῇ" "Γῇ" "image: Γ")
                       (drow "7" "x" "y" "ζ" "ζ" "TODO zoom")      ; stale TODO: dropped
                       (drow "8" "p" "q" "ω" "ω" "image: omega")   ; settled, matches nothing: kept
                       (drow "8" "-" "-" "ω" "ω" "ambiguous: ink"))))  ; a flag: kept
  (lambda (matches decisions orphans)
    (check matches '(0 1 4))
    (check (map (lambda (d) (and d (list (fourth d) (fifth d) (ninth d)))) decisions)
           '(("3" "ὁ" "image: rough breathing") ("5" "Τῇ" "image: Γ") ("8" "p" "image: omega")
             ("8" "-" "ambiguous: ink") #f))
    (check orphans '(2 3))))
;; A line inserted above: the settled row follows its token to the next line.
(call-with-values
    (lambda () (reconcile (list (crow 6 "Τῇ" "Τῇ" "Γῇ")) (list (drow "5" "Τῇ" "Τῇ" "Γῇ" "Γῇ" "image: Γ"))))
  (lambda (matches decisions orphans)
    (check (map fourth decisions) '("6"))
    (check orphans '())))
;; A TODO row nobody settled takes the page's current reading after an edit.
(call-with-values
    (lambda () (reconcile (list (crow 4 "ὁ" "ὁ" "ὅ")) (list (drow "4" "ὁ" "ὁ" "ὃ" "ὃ" "TODO zoom"))))
  (lambda (matches decisions orphans)
    (check (map eighth decisions) '("ὅ"))))

;; Settled rows whose word left their line are open again, unless a later row
;; near it corrects the same letters (a flag left behind by a shifted line).
(let ((toks (page-tokens (parse-page "{C1}{1}καὶ ὅ θεός\nὃ ἐὰν\nὪξ ἐκεῖ.¶\n")))
      (ds (list (drow "1" "ὅ" "ὅ" "ὁ" "ὃ" "image: d-shape")       ; 0: ὃ left line 1 (an ὃ on line 2 is another word): open
                (drow "3" "-" "-" "Ὣξ" "Ὣξ" "ambiguous: rough")  ; 1: superseded by row 2
                (drow "3" "-" "-" "Ὢξ" "Ὢξ" "corrected")         ; 2: on its line
                (drow "3" "-" "-" "{2}ἐκεῖ.¶" "{2}ἐκεῖ.¶" "image") ; 3: old row with markers: on its line
                (drow "2" "-" "-" "Ὢξ" "Ὢξ" "image")             ; 4: shifted flag (line 2): superseded by row 5
                (drow "3" "-" "-" "Ὢξ" "Ὢξ" "image: re-flagged") ; 5
                (drow "1" "-" "-" "θεὸς" "θεὸς" "image"))))      ; 6: θεός on the page: open
  (check (stale-rows ds '(0 1 3 4 6) toks) '(0 6)))

;;; OCR tokens: the question mark after Swete's thin space

(check (map first (ocr-tokens (list (list 0 10 (list '(0 0 10 10 "ἐστιν") '(12 0 14 10 ";") '(20 0 30 10 "καὶ"))))))
       '("ἐστιν;" "καὶ"))

;;; Indentation hints

(define (ocr-line y x0 . words)
  (list y (+ y 60) (map (lambda (w i) (list (+ x0 (* i 200)) y (+ x0 (* i 200) 180) (+ y 60) w)) words (iota (length words)))))
(define hint-page (parse-page "{C1}{1}καὶ ἦν\nτὸ φῶς\nκαὶ ἐγένετο\n{P}Καὶ εἶπεν\n{S}ὁ θεὸς\n"))
(check (indent-hints (list (ocr-line 0 100 "15" "καὶ" "ἦν")   ; a margin number caught in the box
                           (ocr-line 70 300 "τὸ" "φῶς")
                           (ocr-line 140 300 "ἐγένετο")       ; both OCRs lost καὶ: not judged
                           (ocr-line 210 400 "Καὶ" "εἶπεν")
                           (ocr-line 280 300 "ὁ" "θεὸς"))      ; {S} need not look indented
                     hint-page)
       '())
(check (indent-hints (list (ocr-line 0 300 "καὶ" "ἦν") (ocr-line 70 300 "τὸ" "φῶς") (ocr-line 140 450 "καὶ" "ἐγένετο")
                           (ocr-line 210 300 "Καὶ" "εἶπεν") (ocr-line 280 300 "ὁ" "θεὸς"))
                     hint-page)
       '("line 3 looks indented in the scan: a new paragraph? (add {P} at its start, or {S} for a line of poetry)"
         "line 4 has {P} but does not look indented: check the image"))
;; A block set narrower beside a double margin column (Num 1, leaf 285): lines
;; 2-3 start right of the page's flush edge together; no paragraph.
(check (indent-hints (list (ocr-line 0 300 "καὶ" "ἦν") (ocr-line 70 450 "τὸ" "φῶς") (ocr-line 140 450 "καὶ" "ἐγένετο")
                           (ocr-line 210 300 "Καὶ" "εἶπεν") (ocr-line 280 300 "ὁ" "θεὸς"))
                     hint-page)
       '("line 4 has {P} but does not look indented: check the image"))
;; {P} is judged against its prose neighbors: the block shifted right above it
;; (a wider margin-number column, Deut leaf 437), or poetry around it (448).
(check (indent-hints (list (ocr-line 0 300 "καὶ" "ἦν") (ocr-line 70 450 "τὸ" "φῶς") (ocr-line 140 450 "καὶ" "ἐγένετο")
                           (ocr-line 210 400 "Καὶ" "εἶπεν") (ocr-line 280 300 "καὶ" "ἦν"))
                     (parse-page "{C1}{1}καὶ ἦν\nτὸ φῶς\nκαὶ ἐγένετο\n{P}Καὶ εἶπεν\nκαὶ ἦν\n"))
       '())
(check (indent-hints (list (ocr-line 0 300 "καὶ" "ἦν") (ocr-line 70 400 "τὸ" "φῶς") (ocr-line 140 300 "καὶ" "ἐγένετο")
                           (ocr-line 210 400 "Καὶ" "εἶπεν"))
                     (parse-page "{C1}{1}καὶ ἦν\n{S}τὸ φῶς\n{P}καὶ ἐγένετο\n{S}Καὶ εἶπεν\n"))
       '())


;;; Box suggestion: a short last line comes in, the running head and the
;;; apparatus (unaccented, after a wider gap) stay out.

(define (hocr-of-lines ls)
  (string-append
   "<div class='ocr_page' title='bbox 0 0 2000 3000'>"
   (string-concatenate
    (map (match-lambda
           ((y x0 . words)
            (string-append
             (format #f "<span class='ocr_line' title=\"bbox ~a ~a 1900 ~a\">" x0 y (+ y 60))
             (string-concatenate
              (map (lambda (w i) (format #f "<span class='ocrx_word' title='bbox ~a ~a ~a ~a'>~a</span>" (+ x0 (* i 220)) y (+ x0 (* i 220) 200) (+ y 60) w))
                   words (iota (length words))))
             "</span>")))
         ls))
   "</div>"))
(define full '("καὶ" "εἶπεν" "ὁ" "θεὸς" "Γενηθήτω" "φῶς" "ἐγένετο"))
(define box-hocr
  (hocr-of-lines
   (append (list '(100 800 "ΓΕΝΕΣΙΣ" "ΙΙ"))                                   ; running head
           (map (lambda (k) (cons* (+ 200 (* 72 k)) 300 full)) (iota 6))      ; text lines
           (list '(632 300 "καὶ" "ἐγένετο"))                                  ; short last line
           (map (lambda (k) (cons* (+ 780 (* 55 k)) 300 '("και" "ειπεν" "ο" "θεος" "γενηθητω" "φως"))) (iota 3)))))
(check (suggest-box (hocr-lines box-hocr) 2000 3000) '(175 717 275 1840))


(if (zero? failures)
    (format #t "swete: all checks passed~%")
    (begin (format #t "swete: ~a check(s) failed~%" failures) (exit 1)))
