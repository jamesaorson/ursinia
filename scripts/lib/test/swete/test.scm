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
(check (messages (list (page 39 "# s leaf 0039\n# box 1 2 3 4\n{C31}{1}ξ.\n") p92) #f #f) '((40 1 fail)))  ; 1 -> 46 across the leaves
(check (messages (list p92) #f #f) '())
(call-with-values (lambda () (book-verses (list (page 39 "# s\n{C31}{45}x.\n") p92)))
  (lambda (rows problems)
    (check (map second rows) '(45 46 "48a" 47 51 "52a" "48b" 49 "50a" "52b" 53))))
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{49}α. {50}β. {52}γ.\n")) #f #f)
       '((40 1 fail)))                                   ; an unmarked skip still fails
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{49}α. {50!}β.\n")) #f #f)
       '((40 1 fail)))                                   ; {n!} where nothing is skipped
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C31}{1}α. {2}{=31:5}β. {3}γ. {4}{=31:5}δ.\n")) #f #f)
       '((40 1 fail)))                                   ; the same common verse twice
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C31}{1}α. {2}{=31:1a}β.\n")) #f #f)
       '((40 1 fail)))                                   ; a whole verse and a half of it
(check (messages (list (page 40 "# s leaf 0040\n# box 1 2 3 4\n{C31}{1}α. {=31:1}β.\n")) #f #f)
       '())                                              ; the same reference running on is one row

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
    (check orphans '(2))))
;; A line inserted above: the settled row follows its token to the next line.
(call-with-values
    (lambda () (reconcile (list (crow 6 "Τῇ" "Τῇ" "Γῇ")) (list (drow "5" "Τῇ" "Τῇ" "Γῇ" "Γῇ" "image: Γ"))))
  (lambda (matches decisions orphans)
    (check (map fourth decisions) '("6"))
    (check orphans '())))

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
